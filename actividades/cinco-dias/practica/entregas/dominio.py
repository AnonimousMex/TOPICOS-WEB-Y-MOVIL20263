import json
import math
from dataclasses import dataclass
from xml.etree import ElementTree

@dataclass(frozen=True)
class Sugerencia:
    medio: str
    motivo: str

class ProveedorNoDisponible(Exception):
    pass

class Medio:
    nombre = ''
    capacidad = 0
    velocidad = 1
    alcance = 500
    def planear(self, kg, km):
        if kg > self.capacidad or km > self.alcance:
            raise ValueError('El paquete excede la capacidad o alcance del medio')
        return max(1, math.ceil(km / self.velocidad * 60))

class Camioneta(Medio):
    nombre, capacidad, velocidad = 'camioneta', 1000, 40

class Motocicleta(Medio):
    nombre, capacidad, velocidad, alcance = 'motocicleta', 20, 30, 50

class Bicicleta(Medio):
    nombre, capacidad, velocidad, alcance = 'bicicleta', 5, 15, 8

class Dron(Medio):
    nombre, capacidad, velocidad, alcance = 'dron', 2.5, 50, 15

MEDIOS = {m.nombre: m for m in (Camioneta, Motocicleta, Bicicleta, Dron)}

def crear_medio(nombre):
    try: return MEDIOS[nombre]()
    except KeyError: raise ValueError('Medio desconocido')

def proveedor(kg, km, formato, caido=False):
    if caido: raise ProveedorNoDisponible('El proveedor de IA está apagado')
    medio = 'camioneta' if kg > 20 or km > 50 else 'dron' if kg <= 2.5 and km <= 15 else 'bicicleta' if kg <= 5 and km <= 8 else 'motocicleta'
    if formato == 'json': return json.dumps({'route_hint': medio, 'score': .8})
    if formato == 'xml': return f'<suggestion><vehicle>{medio}</vehicle></suggestion>'
    raise ValueError('Formato desconocido')

def adaptar(raw, formato):
    # El vocabulario del proveedor termina en este borde.
    medio = json.loads(raw)['route_hint'] if formato == 'json' else ElementTree.fromstring(raw).findtext('vehicle')
    if medio not in MEDIOS: raise ValueError('Respuesta de proveedor inválida')
    return Sugerencia(medio, f'Proveedor de demostración adaptado desde {formato.upper()}')
