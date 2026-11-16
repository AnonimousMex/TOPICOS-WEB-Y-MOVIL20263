"""Ejecuta el flujo completo contra el servidor en marcha y guarda las respuestas reales.
Uso: python ../evidencias/generar_evidencias.py   (con `manage.py runserver` activo)"""
import json
import urllib.request

BASE = "http://localhost:8000/api"


def post(ruta, datos):
    req = urllib.request.Request(BASE + ruta, json.dumps(datos).encode(), {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


corregido = post("/pedidos/", {"tipo": "guitarra", "valor_mxn": 15200, "peso_kg": 2.6, "dimension_max_cm": 105, "distancia_km": 40, "fragil": False, "producto_id": 2})
confirmado = post("/pedidos/", {"tipo": "percusion", "valor_mxn": 1900, "peso_kg": 4.5, "dimension_max_cm": 50, "distancia_km": 80, "fragil": False, "producto_id": 11})
folio = corregido["folio"]
preguntas = [
    "hola, buenas tardes",
    f"¿cómo va mi pedido {folio}?",
    f"¿por qué me salió embalaje premium? {folio}",
    "¿qué embalaje necesita mi violín?",
    "¿necesito amplificador para una guitarra eléctrica?",
    "¿cuánto cuesta el violín?",
    "¿puedo devolver una guitarra?",
    "cuéntame un chiste",
]
chat = [{"pregunta": q, "respuesta": post("/asistente/", {"mensaje": q})} for q in preguntas]
json.dump({"pedido_corregido_por_reglas": corregido, "pedido_confirmado_por_reglas": confirmado, "chat": chat}, open(__file__.replace("generar_evidencias.py", "flujo.json"), "w"), ensure_ascii=False, indent=2)
for c in chat:
    print(f"> {c['pregunta']}\n  [{c['respuesta']['intencion']} {c['respuesta']['confianza']}] {c['respuesta']['respuesta'][:150]}")
