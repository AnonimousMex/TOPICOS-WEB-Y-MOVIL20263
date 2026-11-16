"""Recomendador de embalaje: Adapter con interfaz, como en el curso (`RecomendadorIA`).

* `RecomendadorModelo`  -> modelo entrenado (.joblib): árbol (principal) o bosque.
* `RecomendadorReglas`  -> heurística simple, sin modelo (respaldo si el .joblib no carga).
* `RecomendadorConRespaldo` envuelve a uno principal y cae al de reglas si falla.
`obtener_recomendador()` es la fábrica (con caché). `recomendar()` une modelo + reglas + plan.
"""
import os
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

import joblib
import pandas as pd

from .niveles import crear_nivel
from .reglas import NIVELES, aplicar_reglas

CARPETA = Path(__file__).resolve().parent.parent / "ml" / "modelos"
VALORES_POR_DEFECTO = {"condicion": "nuevo", "cantidad": 1, "humedad_destino": "media", "zona_riesgo": "baja", "temporada": "secas", "urgente": 0}


@dataclass
class Sugerencia:
    nivel: str
    confianza: float
    ranking: list = field(default_factory=list)  # [{"nivel", "probabilidad"}]
    origen: str = ""


class RecomendadorIA(ABC):
    nombre = ""

    @abstractmethod
    def sugerir(self, entradas) -> Sugerencia:
        """Devuelve el nivel de embalaje estimado, sin reglas de negocio."""

    def metricas(self):
        return {}


def _completar(entradas):
    return {**VALORES_POR_DEFECTO, **entradas, "fragil": int(bool(entradas["fragil"])), "urgente": int(bool(entradas.get("urgente", 0)))}


class RecomendadorModelo(RecomendadorIA):
    def __init__(self, variante="arbol"):
        ruta = CARPETA / f"recomendador_{variante}.joblib"
        if not ruta.exists():
            raise FileNotFoundError(f"Falta {ruta.name}. Ejecuta: python ml/entrenar_recomendador.py")
        paquete = joblib.load(ruta)
        self.nombre, self._modelo, self._columnas, self._metricas = f"modelo_{variante}", paquete["modelo"], paquete["columnas"], paquete["metricas"]

    def sugerir(self, entradas):
        datos = _completar(entradas)
        fila = pd.DataFrame([{c: datos[c] for c in self._columnas}])
        probas = self._modelo.predict_proba(fila)[0]
        ranking = sorted(({"nivel": c, "probabilidad": round(float(p), 4)} for c, p in zip(self._modelo.classes_, probas)), key=lambda r: -r["probabilidad"])
        return Sugerencia(ranking[0]["nivel"], ranking[0]["probabilidad"], ranking, self.nombre)

    def metricas(self):
        return self._metricas


class RecomendadorReglas(RecomendadorIA):
    """Respaldo sin modelo: puntúa el riesgo con una fórmula parecida a la del dataset."""

    nombre = "reglas_simples"

    def sugerir(self, entradas):
        e = _completar(entradas)
        pts = e["valor_mxn"] / 9000 + e["distancia_km"] / 900 + 0.6 * e["fragil"] + (0.5 if e["peso_kg"] > 15 else 0)
        pts += {"baja": 0, "media": 0.3, "alta": 0.7}[e["zona_riesgo"]] + (0.8 if e["tipo"] in ("cuerda_frotada", "guitarra") else 0.3)
        nivel = "basico" if pts < 2.2 else ("reforzado" if pts < 3.7 else "premium")
        ranking = [{"nivel": n, "probabilidad": 0.6 if n == nivel else 0.2} for n in NIVELES]
        return Sugerencia(nivel, 0.6, ranking, self.nombre)


class RecomendadorConRespaldo(RecomendadorIA):
    def __init__(self, principal, respaldo):
        self.principal, self.respaldo, self.nombre = principal, respaldo, principal.nombre

    def sugerir(self, entradas):
        try:
            return self.principal.sugerir(entradas)
        except Exception:  # noqa: BLE001  (el respaldo existe justamente para cualquier fallo del modelo)
            return self.respaldo.sugerir(entradas)

    def metricas(self):
        return self.principal.metricas()


@lru_cache(maxsize=4)
def obtener_recomendador(nombre=None):
    nombre = nombre or os.environ.get("RECOMENDADOR", "arbol")
    if nombre == "reglas":
        return RecomendadorReglas()
    try:
        return RecomendadorConRespaldo(RecomendadorModelo(nombre), RecomendadorReglas())
    except FileNotFoundError:
        return RecomendadorReglas()


def metricas_modelo():
    salida = {}
    for variante in ("arbol", "bosque"):
        try:
            salida[variante] = RecomendadorModelo(variante).metricas()
        except FileNotFoundError:
            pass
    return salida


def factores(e):
    f = []
    if e["valor_mxn"] >= 8000:
        f.append(f"valor alto (${e['valor_mxn']:,.0f})")
    if e["distancia_km"] >= 800:
        f.append(f"larga distancia ({e['distancia_km']} km)")
    if e.get("fragil"):
        f.append("pieza frágil")
    if e.get("humedad_destino") == "alta":
        f.append("humedad alta en el destino")
    if e.get("zona_riesgo") == "alta":
        f.append("zona de riesgo alto")
    if e["peso_kg"] >= 20 or e["dimension_max_cm"] >= 120:
        f.append("pieza grande o pesada")
    if e.get("cantidad", 1) > 1:
        f.append(f"{e['cantidad']} piezas")
    if e.get("urgente"):
        f.append("envío urgente")
    return f


def recomendar(entradas):
    """Modelo + reglas + plan de embalaje + razón en texto."""
    s = obtener_recomendador().sugerir(entradas)
    nivel_final, reglas = aplicar_reglas(s.nivel, entradas)
    plan = crear_nivel(nivel_final).plan({**VALORES_POR_DEFECTO, **entradas})
    fs = factores(entradas)
    razon = f"El modelo ({s.origen}) sugirió «{s.nivel}» con {s.confianza:.0%} de confianza"
    razon += f", considerando: {', '.join(fs)}." if fs else "."
    if reglas:
        razon += " Las reglas de seguridad lo ajustaron a «%s»: %s" % (nivel_final, " ".join(r["motivo"] for r in reglas))
    return {
        "nivel_modelo": s.nivel, "confianza": s.confianza, "nivel_final": nivel_final, "corregido_por_reglas": nivel_final != s.nivel,
        "reglas": reglas, "ranking": s.ranking, "descripcion": plan["descripcion"], "costo_embalaje_mxn": plan["costo_mxn"],
        "razon": razon, "plan": plan, "modelo": s.origen, "niveles": NIVELES,
    }
