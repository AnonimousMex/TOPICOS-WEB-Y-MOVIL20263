import math
from pathlib import Path
import joblib
import pandas as pd
from flask import Flask, jsonify, request
from reglas import es_posible

app = Flask(__name__)
NUMERICAS = ['distancia_km','peso_kg','largo_cm','ancho_cm','alto_cm','volumen_l','fragil','refrigerado','valor_declarado_mxn','hora_salida']
CATEGORIAS = {'prioridad': {'normal','express','mismo_dia'}, 'zona_destino': {'centro','residencial','periferia','rural'}, 'clima': {'despejado','lluvia','viento_fuerte'}, 'trafico': {'bajo','medio','alto'}}
MODELOS = {p.stem: joblib.load(p) for p in (Path(__file__).parent / 'modelo').glob('*.joblib')}

def validar(datos):
    if not isinstance(datos, dict):
        raise ValueError('Se requiere un objeto JSON.')
    p = {}
    for campo in NUMERICAS:
        valor = datos.get(campo)
        if isinstance(valor, bool) or not isinstance(valor, (int, float)) or not math.isfinite(valor):
            raise ValueError(f'{campo} debe ser un número finito.')
        if valor < 0:
            raise ValueError(f'{campo} no puede ser negativo.')
        p[campo] = valor
    for campo, opciones in CATEGORIAS.items():
        if datos.get(campo) not in opciones:
            raise ValueError(f'{campo} no pertenece al catálogo.')
        p[campo] = datos[campo]
    if p['hora_salida'] != int(p['hora_salida']) or p['hora_salida'] > 23:
        raise ValueError('hora_salida debe ser un entero de 0 a 23.')
    if any(p[c] not in (0, 1) for c in ['fragil', 'refrigerado']):
        raise ValueError('fragil y refrigerado deben valer 0 o 1.')
    return p

@app.get('/salud')
def salud():
    return jsonify(servicio='recomendar', estado='ok', modelos=sorted(MODELOS))

@app.post('/sugerir')
def sugerir():
    datos = request.get_json(silent=True)
    try:
        paquete = validar(datos)
    except ValueError as error:
        return jsonify(error=str(error)), 400
    nombre = datos.get('modelo', 'arbol')
    if nombre not in MODELOS:
        return jsonify(error='Modelo no disponible.', modelos=sorted(MODELOS)), 400
    modelo = MODELOS[nombre]
    probabilidades = modelo.predict_proba(pd.DataFrame([paquete]))[0]
    ranking = sorted(zip(modelo.classes_, probabilidades), key=lambda par: -par[1])
    viables = [(m, float(p)) for m, p in ranking if es_posible(m, paquete)]
    if not viables:
        return jsonify(error='No hay un medio viable para este paquete.'), 422
    elegido, confianza = viables[0]
    preferido = ranking[0][0]
    corregido = elegido != preferido
    motivo = f'{nombre}: {elegido}; confianza de hoja/modelo {confianza:.1%}.'
    if corregido:
        motivo += f' Las reglas descartaron {preferido}.'
    return jsonify(servicio='recomendar', modelo=nombre, medio=elegido, motivo=motivo,
                   preferido_por_modelo=preferido, corregido_por_reglas=corregido,
                   ranking=[{'medio': m, 'probabilidad': float(p)} for m,p in ranking])
