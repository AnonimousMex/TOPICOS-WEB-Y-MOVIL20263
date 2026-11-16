from django.db import models


class Producto(models.Model):
    CATEGORIAS = [
        ("guitarra", "Guitarra"),
        ("teclado", "Teclado"),
        ("viento", "Viento"),
        ("percusion", "Percusión"),
        ("cuerda_frotada", "Cuerda frotada"),
        ("accesorio", "Accesorio"),
    ]
    nombre = models.CharField(max_length=120)
    marca = models.CharField(max_length=60)
    categoria = models.CharField(max_length=20, choices=CATEGORIAS)
    descripcion = models.TextField(blank=True)
    precio_mxn = models.DecimalField(max_digits=10, decimal_places=2)
    peso_kg = models.DecimalField(max_digits=6, decimal_places=2)
    dimension_max_cm = models.PositiveIntegerField()
    fragil = models.BooleanField(default=True)
    existencias = models.PositiveIntegerField(default=0)
    subcategoria = models.CharField(max_length=40, blank=True)
    precio_original_mxn = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    rating = models.FloatField(default=4.5)
    vendidos = models.PositiveIntegerField(default=0)
    envio_gratis = models.BooleanField(default=False)
    imagen_url = models.CharField(max_length=300, blank=True)  # ruta /img/... o URL absoluta con foto del producto
    imagen_credito = models.CharField(max_length=200, blank=True)  # autor y licencia de la foto
    imagen_fuente = models.URLField(max_length=300, blank=True)  # página de la foto en Wikimedia Commons
    imagen_nivel = models.CharField(max_length=12, blank=True)  # modelo | marca | referencia

    class Meta:
        ordering = ["categoria", "nombre"]

    @property
    def descuento_pct(self):
        if self.precio_original_mxn and self.precio_original_mxn > self.precio_mxn:
            return int(round((1 - self.precio_mxn / self.precio_original_mxn) * 100))
        return 0

    def __str__(self):
        return self.nombre


class Compra(models.Model):
    """Una compra del carrito: agrupa pedidos (uno por producto), el pago simulado y el correo."""

    referencia = models.CharField(max_length=20, unique=True, blank=True)
    cliente = models.CharField(max_length=80)
    correo = models.EmailField()
    destino = models.CharField(max_length=40)
    lat_aprox = models.FloatField(null=True, blank=True)  # solo si compró con "mi ubicación"; redondeada a ~1 km
    lon_aprox = models.FloatField(null=True, blank=True)
    subtotal_mxn = models.DecimalField(max_digits=12, decimal_places=2)
    embalaje_mxn = models.DecimalField(max_digits=10, decimal_places=2)
    total_mxn = models.DecimalField(max_digits=12, decimal_places=2)
    pago_estado = models.CharField(max_length=12, default="aprobado")
    pago_marca = models.CharField(max_length=12, blank=True)
    pago_ultimos4 = models.CharField(max_length=4, blank=True)  # NUNCA se guarda el número completo ni el CVV
    pago_referencia = models.CharField(max_length=20, blank=True)
    creado = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.referencia:
            self.referencia = f"CMP-{self.creado.year}-{self.pk:06d}"
            super().save(update_fields=["referencia"])

    def __str__(self):
        return self.referencia


class Correo(models.Model):
    """Bandeja de salida: cada correo de confirmación queda registrado, se haya enviado o no."""

    compra = models.ForeignKey(Compra, null=True, blank=True, on_delete=models.SET_NULL, related_name="correos")
    para = models.EmailField()
    asunto = models.CharField(max_length=200)
    texto = models.TextField()
    html = models.TextField(blank=True)
    estado = models.CharField(max_length=10)  # enviado | simulado | error
    error = models.CharField(max_length=300, blank=True)
    creado = models.DateTimeField(auto_now_add=True)


class ConsultaAsistente(models.Model):
    """Observabilidad: qué se preguntó, qué decidió cada capa y cuánto tardó (sin datos personales)."""

    sesion = models.CharField(max_length=40, blank=True)
    mensaje = models.CharField(max_length=300)
    intencion = models.CharField(max_length=30)
    confianza = models.FloatField(default=0)
    latencia_ms = models.PositiveIntegerField(default=0)
    resultado = models.CharField(max_length=12, default="ok")  # ok | abstencion | bloqueado | escalado
    capas = models.JSONField(default=list)
    feedback = models.SmallIntegerField(null=True, blank=True)  # 1 útil, -1 no útil
    creado = models.DateTimeField(auto_now_add=True)


class ContextoAsistente(models.Model):
    """Memoria corta de la conversación (último producto, marca, folio verificado…)."""

    sesion = models.CharField(max_length=40, unique=True)
    datos = models.JSONField(default=dict)
    actualizado = models.DateTimeField(auto_now=True)


class Pedido(models.Model):
    """Orden con la recomendación de embalaje y seguro que se calculó al registrarla."""

    folio = models.CharField(max_length=20, unique=True, blank=True)
    compra = models.ForeignKey(Compra, null=True, blank=True, on_delete=models.SET_NULL, related_name="pedidos")
    producto = models.ForeignKey(Producto, null=True, blank=True, on_delete=models.SET_NULL)
    cliente = models.CharField(max_length=80, blank=True)
    destino = models.CharField(max_length=40, blank=True)
    cantidad = models.PositiveIntegerField(default=1)
    costo_embalaje_mxn = models.PositiveIntegerField(default=0)
    estado = models.CharField(max_length=20, default="registrado")
    tipo = models.CharField(max_length=20)
    valor_mxn = models.DecimalField(max_digits=10, decimal_places=2)
    peso_kg = models.DecimalField(max_digits=6, decimal_places=2)
    dimension_max_cm = models.PositiveIntegerField()
    distancia_km = models.PositiveIntegerField()
    fragil = models.BooleanField()
    nivel_modelo = models.CharField(max_length=20)
    confianza = models.FloatField()
    nivel_final = models.CharField(max_length=20)
    reglas = models.JSONField(default=list)
    ranking = models.JSONField(default=list)
    creado = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.folio:
            self.folio = f"MUS-{self.creado.year}-{self.pk:06d}"
            super().save(update_fields=["folio"])

    @property
    def corregido(self):
        return self.nivel_modelo != self.nivel_final

    def __str__(self):
        return self.folio
