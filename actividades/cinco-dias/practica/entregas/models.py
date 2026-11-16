import uuid
from django.db import models

def nuevo_folio():
    return 'PED-' + uuid.uuid4().hex[:12].upper()

class Pedido(models.Model):
    folio = models.CharField(max_length=20, unique=True, default=nuevo_folio)
    intento = models.UUIDField(unique=True)
    destino = models.CharField(max_length=120)
    kg = models.FloatField()
    km = models.FloatField()
    medio = models.CharField(max_length=20)
    motivo = models.CharField(max_length=240)
    estado = models.CharField(max_length=20, default='registrado')
    eta = models.IntegerField()
    creado = models.DateTimeField(auto_now_add=True)
