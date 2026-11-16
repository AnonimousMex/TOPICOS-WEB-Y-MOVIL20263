from django.core.management.base import BaseCommand

from catalogo.datos_catalogo import construir
from catalogo.imagenes import foto_de
from catalogo.models import Producto


class Command(BaseCommand):
    help = "Carga el catálogo demo (51 marcas, ~190 productos con foto cuando existe). Reemplaza el catálogo anterior sin tocar los pedidos."

    def handle(self, *args, **opciones):
        filas = construir()
        nombres = {f["nombre"] for f in filas}
        Producto.objects.exclude(nombre__in=nombres).delete()  # elimina el catálogo viejo (los pedidos conservan su historial)
        nuevos = 0
        for f in filas:
            foto = foto_de(f['nombre'])
            if foto:
                f.update(imagen_url=foto[0], imagen_credito=foto[1], imagen_fuente=foto[2], imagen_nivel=foto[3])
            _, creado = Producto.objects.update_or_create(nombre=f["nombre"], defaults=f)
            nuevos += creado
        marcas = Producto.objects.values("marca").distinct().count()
        self.stdout.write(self.style.SUCCESS(f"{len(filas)} productos de {marcas} marcas listos ({nuevos} nuevos)."))
