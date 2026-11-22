from getpass import getpass

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from catalogo.autenticacion import validar_contrasena
from catalogo.validacion import EntradaInvalida


class Command(BaseCommand):
    help = "Crea (o promueve) un usuario ADMIN: ve la bitácora de auditoría y las métricas del asistente. Ej.: manage.py crear_admin jefe@tienda.mx"

    def add_arguments(self, parser):
        parser.add_argument("correo")
        parser.add_argument("--nombre", default="Administrador")

    def handle(self, *args, **o):
        correo = o["correo"].strip().lower()
        contrasena = getpass("Contraseña (no se muestra): ")
        try:
            validar_contrasena(contrasena)
        except EntradaInvalida as e:
            raise CommandError(next(iter(e.errores.values())))
        U = get_user_model()
        u, _ = U.objects.get_or_create(username=correo, defaults={"email": correo, "first_name": o["nombre"]})
        u.email, u.is_staff = correo, True
        u.set_password(contrasena)
        u.save()
        self.stdout.write(self.style.SUCCESS(f"Administrador listo: {correo}"))
