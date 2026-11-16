"""Usa el recomendador desde la terminal (sin servidor): modelo + reglas + plan de embalaje.

Ejemplos (desde backend/):
    python ml/usar_modelo.py --tipo guitarra --valor 15200 --peso 2.6 --dimension 105 --km 40
    python ml/usar_modelo.py --tipo violin_no --help   # ver todas las opciones
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from catalogo.recomendador import recomendar  # noqa: E402

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("--tipo", required=True, choices=["guitarra", "teclado", "viento", "percusion", "cuerda_frotada", "accesorio"])
ap.add_argument("--valor", type=float, required=True, help="valor en MXN")
ap.add_argument("--peso", type=float, required=True, help="peso en kg")
ap.add_argument("--dimension", type=int, required=True, help="dimensión mayor en cm")
ap.add_argument("--km", type=int, required=True, help="distancia de envío en km")
ap.add_argument("--no-fragil", action="store_true")
ap.add_argument("--cantidad", type=int, default=1)
ap.add_argument("--humedad", choices=["baja", "media", "alta"], default="media")
ap.add_argument("--zona", choices=["baja", "media", "alta"], default="baja")
ap.add_argument("--temporada", choices=["secas", "lluvias"], default="secas")
ap.add_argument("--usado", action="store_true")
ap.add_argument("--urgente", action="store_true")
a = ap.parse_args()

r = recomendar({
    "tipo": a.tipo, "condicion": "usado" if a.usado else "nuevo", "valor_mxn": a.valor, "peso_kg": a.peso,
    "dimension_max_cm": a.dimension, "distancia_km": a.km, "fragil": not a.no_fragil, "cantidad": a.cantidad,
    "humedad_destino": a.humedad, "zona_riesgo": a.zona, "temporada": a.temporada, "urgente": a.urgente,
})
print(json.dumps(r, ensure_ascii=False, indent=2))
