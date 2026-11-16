"""Genera el dataset SINTÉTICO de envíos de instrumentos musicales (Python + pandas/numpy).

Uso (desde backend/):
    python ml/generar_dataset.py                       # 10,000 filas, semilla 7
    python ml/generar_dataset.py --filas 5000 --semilla 3 --faltantes 0.03

Salida: ml/datos/envios_instrumentos.csv  (id_envio + 12 columnas de entrada + nivel_embalaje)

Cómo se etiqueta: una "puntuación de riesgo" que suma tipo de instrumento, valor, distancia, fragilidad,
peso, humedad del destino (solo daña a instrumentos de madera), zona de riesgo, temporada de lluvias,
urgencia, condición y cantidad, más ruido gaussiano y un 5 % de etiquetas cambiadas a propósito.
Es una REGLA DE NEGOCIO PLAUSIBLE más ruido, no envíos reales: las métricas no miden el mundo real.
"""
import argparse
from pathlib import Path

import numpy as np
import pandas as pd

NIVELES = ["basico", "reforzado", "premium"]
TIPOS = ["guitarra", "teclado", "viento", "percusion", "cuerda_frotada", "accesorio"]
NIVEL3 = ["baja", "media", "alta"]
MADERA = {"guitarra", "cuerda_frotada", "percusion"}  # sensibles a humedad
COLUMNAS_ENTRADA = ["tipo", "condicion", "valor_mxn", "peso_kg", "dimension_max_cm", "distancia_km", "fragil",
                    "cantidad", "humedad_destino", "zona_riesgo", "temporada", "urgente"]
NUMERICAS = ["valor_mxn", "peso_kg", "dimension_max_cm", "distancia_km", "fragil", "cantidad", "urgente"]
CATEGORICAS = ["tipo", "condicion", "humedad_destino", "zona_riesgo", "temporada"]
UMBRALES = (2.2, 3.7)  # calibrados para ~25 % básico, ~40 % reforzado, ~35 % premium
DESTINO = Path(__file__).resolve().parent / "datos" / "envios_instrumentos.csv"

# (valor mediana, peso medio, dimensión media cm, riesgo base del tipo)
PERFIL = {
    "guitarra": (6500, 3.5, 110, 1.0), "teclado": (9000, 9.0, 100, 0.8), "viento": (7000, 1.8, 65, 1.0),
    "percusion": (5500, 12.0, 85, 0.6), "cuerda_frotada": (8500, 1.5, 80, 1.6), "accesorio": (700, 0.6, 30, 0.1),
}


def puntuar(tipo, condicion, valor, peso, dist, fragil, cantidad, humedad, zona, temporada, urgente, ruido):
    pts = PERFIL[tipo][3] + valor / 9000 + dist / 900 + 0.6 * fragil + (0.5 if peso > 15 else 0)
    pts += {"baja": 0, "media": 0.3, "alta": 0.7}[zona]
    if tipo in MADERA:
        pts += {"baja": 0, "media": 0.2, "alta": 0.5}[humedad] + (0.25 if temporada == "lluvias" and humedad != "baja" else 0)
    pts += 0.2 * urgente + (0.3 if condicion == "usado" else 0) + 0.15 * (cantidad - 1)
    return pts + ruido


def generar(filas=10000, semilla=7, faltantes=0.0):
    rng = np.random.default_rng(semilla)
    registros = []
    for i in range(filas):
        tipo = rng.choice(TIPOS, p=[0.26, 0.2, 0.14, 0.14, 0.08, 0.18])
        v0, p0, d0, _ = PERFIL[tipo]
        cantidad = int(rng.choice([1, 2, 3, 4], p=[0.78, 0.15, 0.05, 0.02]))
        valor = float(np.clip(rng.lognormal(np.log(v0), 0.7), 80, 90000)) * cantidad
        peso = float(np.clip(rng.normal(p0, p0 * 0.35), 0.1, 60)) * cantidad
        dim = int(np.clip(rng.normal(d0, d0 * 0.25), 10, 200))
        dist = int(np.clip(rng.gamma(2.0, 280), 5, 2800))
        fragil = int(rng.random() < (0.9 if tipo != "accesorio" else 0.35))
        condicion = "usado" if rng.random() < 0.18 else "nuevo"
        humedad = str(rng.choice(NIVEL3, p=[0.3, 0.45, 0.25]))
        zona = str(rng.choice(NIVEL3, p=[0.35, 0.4, 0.25]))
        temporada = "lluvias" if rng.random() < 0.42 else "secas"
        urgente = int(rng.random() < 0.15)
        pts = puntuar(tipo, condicion, valor, peso, dist, fragil, cantidad, humedad, zona, temporada, urgente, rng.normal(0, 0.35))
        nivel = 0 if pts < UMBRALES[0] else (1 if pts < UMBRALES[1] else 2)
        if rng.random() < 0.05:  # ruido de etiquetado
            nivel = int(np.clip(nivel + rng.choice([-1, 1]), 0, 2))
        registros.append([f"E{i + 1:05d}", tipo, condicion, round(valor, 2), round(peso, 2), dim, dist, fragil, cantidad,
                          humedad, zona, temporada, urgente, NIVELES[nivel]])
    df = pd.DataFrame(registros, columns=["id_envio", "tipo", "condicion", "valor_mxn", "peso_kg", "dimension_max_cm", "distancia_km",
                                          "fragil", "cantidad", "humedad_destino", "zona_riesgo", "temporada", "urgente", "nivel_embalaje"])
    if faltantes > 0:  # huecos al azar en columnas numéricas (para practicar la imputación)
        for col in ["valor_mxn", "peso_kg", "dimension_max_cm", "distancia_km"]:
            df.loc[rng.random(len(df)) < faltantes, col] = np.nan
    return df


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--filas", type=int, default=10000)
    ap.add_argument("--semilla", type=int, default=7)
    ap.add_argument("--faltantes", type=float, default=0.0, help="fracción de valores numéricos que se dejan vacíos (0 a 0.2)")
    ap.add_argument("--salida", type=Path, default=DESTINO)
    a = ap.parse_args()
    if not 0 <= a.faltantes <= 0.2:
        ap.error("--faltantes debe estar entre 0 y 0.2")
    df = generar(a.filas, a.semilla, a.faltantes)
    a.salida.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(a.salida, index=False)
    print(f"{len(df)} filas → {a.salida}\n{df['nivel_embalaje'].value_counts().to_string()}")
    if a.faltantes:
        print("valores vacíos por columna:\n" + df.isna().sum()[lambda x: x > 0].to_string())


if __name__ == "__main__":
    main()
