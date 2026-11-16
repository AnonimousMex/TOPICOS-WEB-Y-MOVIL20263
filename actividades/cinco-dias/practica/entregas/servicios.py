import logging
import math
import uuid
from django.db import transaction
from django.shortcuts import get_object_or_404
from .models import Pedido
from .dominio import adaptar, crear_medio, proveedor

log = logging.getLogger(__name__)

def avisar(folio, fallo=False):
    # Aviso local del laboratorio; no envía mensajes a otras personas.
    if fallo: raise RuntimeError('Aviso de demostración no disponible')
    log.info('Pedido confirmado: %s', folio)

def aviso_posterior(folio, fallo):
    try: avisar(folio, fallo)
    except RuntimeError: log.warning('Aviso pendiente; el pedido %s sigue guardado', folio)

def registrar_pedido(datos):
    kg, km = float(datos['kg']), float(datos['km'])
    if not math.isfinite(kg) or not math.isfinite(km) or kg <= 0 or km <= 0:
        raise ValueError('Peso y distancia deben ser positivos y finitos')
    destino = datos['destino'].strip()
    if not 1 <= len(destino) <= 120: raise ValueError('Destino obligatorio, máximo 120 caracteres')
    intento = uuid.UUID(datos['intento'])
    previo = Pedido.objects.filter(intento=intento).first()
    if previo:
        if (previo.kg, previo.km, previo.destino) != (kg, km, destino):
            raise ValueError('El intento ya pertenece a otros datos')
        return previo
    formato = datos.get('formato', 'json')
    sugerencia = adaptar(proveedor(kg, km, formato, datos.get('ia_caida') == 'on'), formato)
    medio = crear_medio(sugerencia.medio)
    eta = medio.planear(kg, km)
    with transaction.atomic():
        pedido, nuevo = Pedido.objects.get_or_create(intento=intento, defaults=dict(destino=destino, kg=kg, km=km, medio=medio.nombre, motivo=sugerencia.motivo, eta=eta))
        if (pedido.kg, pedido.km, pedido.destino) != (kg, km, destino):
            raise ValueError('El intento ya pertenece a otros datos')
        if nuevo: transaction.on_commit(lambda: aviso_posterior(pedido.folio, datos.get('aviso_caido') == 'on'))
    return pedido

def consultar_pedido(folio):
    return get_object_or_404(Pedido, folio=folio)

def resumen(pedido):
    return dict(folio=pedido.folio, estado=pedido.estado, eta=pedido.eta)
