"""Prueba el recomendador con casos conocidos y muestra dónde las reglas corrigen al modelo.

Uso (desde backend/):  python ml/probar_modelo.py [arbol|bosque|reglas]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import os  # noqa: E402

if len(sys.argv) > 1:
    os.environ["RECOMENDADOR"] = sys.argv[1]
from catalogo.recomendador import recomendar  # noqa: E402

BASE = {"condicion": "nuevo", "cantidad": 1, "humedad_destino": "media", "zona_riesgo": "baja", "temporada": "secas", "urgente": False, "fragil": True}
CASOS = [
    ("Cuerdas D'Addario a 800 km", dict(tipo="accesorio", valor_mxn=249, peso_kg=0.1, dimension_max_cm=15, distancia_km=800, fragil=False)),
    ("Guitarra de $15,200 a 40 km", dict(tipo="guitarra", valor_mxn=15200, peso_kg=2.6, dimension_max_cm=105, distancia_km=40, fragil=False)),
    ("Batería acústica de 32 kg", dict(tipo="percusion", valor_mxn=11990, peso_kg=32, dimension_max_cm=140, distancia_km=300)),
    ("Violín a Veracruz (humedad alta)", dict(tipo="cuerda_frotada", valor_mxn=3500, peso_kg=0.5, dimension_max_cm=60, distancia_km=650, humedad_destino="alta")),
    ("Guitarra $9,000 a Acapulco", dict(tipo="guitarra", valor_mxn=9000, peso_kg=3, dimension_max_cm=105, distancia_km=520, humedad_destino="alta", zona_riesgo="alta")),
    ("Piano digital a Monterrey", dict(tipo="teclado", valor_mxn=12990, peso_kg=11.5, dimension_max_cm=132, distancia_km=900)),
]
print(f"{'caso':<36}{'modelo':<11}{'conf.':<7}{'final':<11}reglas")
corregidos = 0
for nombre, datos in CASOS:
    r = recomendar({**BASE, **datos})
    corregidos += r["corregido_por_reglas"]
    print(f"{nombre:<36}{r['nivel_modelo']:<11}{r['confianza']:<7.0%}{r['nivel_final']:<11}{','.join(x['regla'] for x in r['reglas']) or '-'}")
print(f"\n{corregidos} de {len(CASOS)} casos corregidos por las reglas (modelo usado: {r['modelo']})")
