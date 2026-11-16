"""Entrena el recomendador de embalaje y seguro (fuera de las peticiones HTTP).

Uso (desde backend/):  python ml/entrenar_recomendador.py [--csv RUTA] [--sin-generar]

1. Lee ml/datos/envios_instrumentos.csv (si no existe lo genera con generar_dataset.py).
2. Pipeline: imputación (mediana) + one-hot (handle_unknown="ignore") + modelo.
3. Árbol de decisión (max_depth=8, min_samples_leaf=5) = modelo principal; Random Forest = comparación opcional.
4. Reporta accuracy, precisión/recall/F1 por clase, matriz de confusión, reglas del árbol (export_text)
   y la comparación de profundidades (sobreajuste). Guarda ml/reportes/entrenamiento.md.
Artefactos: ml/modelos/recomendador_arbol.joblib y recomendador_bosque.joblib (con versión de scikit-learn).
"""
import argparse
import sys
from pathlib import Path

import joblib
import pandas as pd
import sklearn
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier, export_text

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generar_dataset import CATEGORICAS, COLUMNAS_ENTRADA, DESTINO, NUMERICAS, generar  # noqa: E402

BASE = Path(__file__).resolve().parent
SEMILLA = 42


def pipeline(modelo):
    prep = ColumnTransformer([
        ("num", SimpleImputer(strategy="median"), NUMERICAS),
        ("cat", OneHotEncoder(handle_unknown="ignore"), CATEGORICAS),
    ])
    return Pipeline([("prep", prep), ("modelo", modelo)])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", type=Path, default=DESTINO)
    ap.add_argument("--sin-generar", action="store_true")
    a = ap.parse_args()
    if not a.csv.exists() and not a.sin_generar:
        a.csv.parent.mkdir(parents=True, exist_ok=True)
        generar().to_csv(a.csv, index=False)
    df = pd.read_csv(a.csv)
    print(f"{df.shape[0]} filas, {df.shape[1]} columnas; clases:\n{df['nivel_embalaje'].value_counts().to_string()}\n")

    X, y = df[COLUMNAS_ENTRADA], df["nivel_embalaje"]  # id_envio NO es una entrada
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, stratify=y, random_state=SEMILLA)

    arbol = pipeline(DecisionTreeClassifier(max_depth=8, min_samples_leaf=5, random_state=SEMILLA)).fit(Xtr, ytr)
    bosque = pipeline(RandomForestClassifier(n_estimators=200, max_depth=10, random_state=SEMILLA)).fit(Xtr, ytr)

    informe = ["# Reporte de entrenamiento del recomendador", "",
               f"scikit-learn {sklearn.__version__} · {len(Xtr)} filas de entrenamiento, {len(Xte)} de prueba (20 %, estratificado, random_state={SEMILLA}).",
               "Datos sintéticos: las métricas describen el dataset, no envíos reales.", ""]
    metricas = {}
    for nombre, modelo in (("arbol", arbol), ("bosque", bosque)):
        pred = modelo.predict(Xte)
        acc = accuracy_score(yte, pred)
        metricas[nombre] = {
            "accuracy_prueba": round(float(acc), 4), "filas_entrenamiento": int(len(Xtr)), "filas_prueba": int(len(Xte)),
            "clases": list(modelo.classes_), "matriz_confusion": confusion_matrix(yte, pred, labels=modelo.classes_).tolist(),
            "sklearn": sklearn.__version__, "nota": "Datos sintéticos; la métrica no mide desempeño en envíos reales.",
        }
        informe += [f"## {'Árbol de decisión (principal)' if nombre == 'arbol' else 'Random Forest (comparación)'}", "",
                    f"Accuracy en prueba: **{acc:.3f}**", "", "```", classification_report(yte, pred), "```", "",
                    "Matriz de confusión (filas = real, columnas = predicho; orden: " + ", ".join(modelo.classes_) + "):", "", "```",
                    str(confusion_matrix(yte, pred, labels=modelo.classes_)), "```", ""]
        print(f"== {nombre}: accuracy {acc:.3f}\n{classification_report(yte, pred)}")

    informe += ["## Profundidad y sobreajuste (árbol)", "", "| max_depth | accuracy entrenamiento | accuracy prueba |", "|---|---|---|"]
    for d in (2, 4, 6, 8, 12, None):
        m = pipeline(DecisionTreeClassifier(max_depth=d, min_samples_leaf=5, random_state=SEMILLA)).fit(Xtr, ytr)
        tr, te = accuracy_score(ytr, m.predict(Xtr)), accuracy_score(yte, m.predict(Xte))
        informe.append(f"| {d if d else 'sin límite'} | {tr:.3f} | {te:.3f} |")
        print(f"profundidad {str(d):>4}: entrenamiento {tr:.3f}  prueba {te:.3f}")
    nombres = list(arbol.named_steps["prep"].get_feature_names_out())
    reglas = export_text(arbol.named_steps["modelo"], feature_names=nombres, max_depth=3)
    informe += ["", "Cuanto más profundo, mejor en entrenamiento y peor (o igual) en prueba: el árbol memoriza el ruido.", "",
                "## Reglas aprendidas (primeros 3 niveles)", "", "```", reglas, "```", ""]

    (BASE / "modelos").mkdir(exist_ok=True)
    (BASE / "reportes").mkdir(exist_ok=True)
    for nombre, modelo in (("arbol", arbol), ("bosque", bosque)):
        joblib.dump({"modelo": modelo, "columnas": COLUMNAS_ENTRADA, "metricas": metricas[nombre]}, BASE / "modelos" / f"recomendador_{nombre}.joblib")
    (BASE / "reportes" / "entrenamiento.md").write_text("\n".join(informe), encoding="utf-8")
    print("\nGuardado: modelos/recomendador_arbol.joblib, recomendador_bosque.joblib y reportes/entrenamiento.md")


if __name__ == "__main__":
    main()
