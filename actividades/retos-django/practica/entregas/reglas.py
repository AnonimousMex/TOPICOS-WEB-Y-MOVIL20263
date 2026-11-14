import os

def elegir_medio(km,kg):
 limite_bici=float(os.environ.get('BICI_MAX_KM','3'))
 if kg>25 or km>40:
  return 'camioneta','El paquete supera el alcance o capacidad de moto.'
 if km<=limite_bici and kg<=8:
  return 'bicicleta',f'Paquete ligero dentro del límite de bicicleta ({limite_bici:g} km).'
 return 'moto','Distancia media y paquete dentro de capacidad de moto.'
