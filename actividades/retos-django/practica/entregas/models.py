from uuid import uuid4
from django.db import models

def nuevo_folio():
 return uuid4().hex[:12].upper()

class Pedido(models.Model):
 folio=models.CharField(max_length=12,unique=True,default=nuevo_folio)
 destino=models.CharField(max_length=240)
 estado=models.CharField(max_length=30,default='registrado')
