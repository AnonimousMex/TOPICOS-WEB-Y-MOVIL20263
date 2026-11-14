import os
from threading import Lock
from uuid import uuid4
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)
RECOMENDAR_URL = os.environ.get('RECOMENDAR_URL', 'http://recomendar:8002').rstrip('/')
pedidos = {}
candado = Lock()

@app.get('/salud')
def salud():
    return jsonify(servicio='pedidos', estado='ok')

@app.get('/pedidos')
def listar():
    with candado:
        return jsonify(pedidos=list(pedidos.values()))

@app.post('/pedidos')
def crear():
    paquete = request.get_json(silent=True)
    if not isinstance(paquete, dict):
        return jsonify(error='Se requiere un objeto JSON.'), 400
    try:
        respuesta = requests.post(f'{RECOMENDAR_URL}/sugerir', json=paquete, timeout=(1, 2))
        sugerencia = respuesta.json()
        if respuesta.status_code in (400, 422):
            return jsonify(sugerencia), respuesta.status_code
        respuesta.raise_for_status()
        if not isinstance(sugerencia, dict) or not all(c in sugerencia for c in ['medio','modelo','motivo']):
            raise ValueError('Respuesta del recomendador incompleta')
    except (requests.RequestException, ValueError):
        return jsonify(servicio='pedidos', error='Recomendador no disponible. El pedido no fue creado; puede reintentar.',
                       estado='recomendacion_pendiente'), 503
    folio = uuid4().hex[:12].upper()
    pedido = {'folio': folio, **sugerencia, 'servicio': 'pedidos'}
    with candado:
        pedidos[folio] = pedido
    return jsonify(pedido), 201
