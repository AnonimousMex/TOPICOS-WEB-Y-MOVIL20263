"""Login con token, roles y bloqueo por intentos (mismo esquema que el servicio auth de Rumbo, a escala de monolito).

- Contraseñas: hash PBKDF2 de Django (Rumbo usa bcrypt; la idea es la misma: nunca se guarda la contraseña).
- Token: `secrets.token_urlsafe`; en la base solo vive su SHA-256 y expira a los 7 días.
- Roles: CLIENTE (usuario normal) y ADMIN (`is_staff`). El servidor decide permisos; Flutter solo muestra u oculta botones.
"""
import hashlib
import re
import secrets
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import check_password
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.utils import timezone

from .models import IntentosLogin, Sesion
from .validacion import EntradaInvalida

User = get_user_model()
VIGENCIA_DIAS = 7
MAX_FALLOS = 5
BLOQUEO_MIN = 15
# Hash de relleno: se compara aunque el correo no exista, para que el tiempo de respuesta no delate qué correos están registrados.
_HASH_FALSO = "pbkdf2_sha256$1000000$relleno$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


class NoAutorizado(Exception):
    def __init__(self, mensaje, status=401, codigo="NO_AUTORIZADO"):
        self.mensaje, self.status, self.codigo = mensaje, status, codigo


def _hash_token(token):
    return hashlib.sha256(token.encode()).hexdigest()


def rol_de(usuario):
    return "ADMIN" if usuario.is_staff else "CLIENTE"


def usuario_json(usuario):
    return {"id": usuario.id, "nombre": usuario.first_name, "correo": usuario.email, "rol": rol_de(usuario)}


def validar_contrasena(valor):
    if not isinstance(valor, str) or len(valor) < 8 or len(valor) > 72:
        raise EntradaInvalida({"contrasena": "Debe tener entre 8 y 72 caracteres."})
    if not (re.search(r"[a-z]", valor) and re.search(r"[A-Z]", valor) and re.search(r"\d", valor)):
        raise EntradaInvalida({"contrasena": "Usa mayúscula, minúscula y número."})
    return valor


def _correo(datos):
    correo = str(datos.get("correo", "")).strip().lower()
    try:
        validate_email(correo)
    except ValidationError:
        raise EntradaInvalida({"correo": "Escribe un correo válido."})
    return correo


def _emitir(usuario, ip):
    token = secrets.token_urlsafe(48)
    Sesion.objects.create(usuario=usuario, token_hash=_hash_token(token), expira=timezone.now() + timedelta(days=VIGENCIA_DIAS), ip=ip or "")
    return token


def registrar(datos, ip=""):
    correo = _correo(datos)
    nombre = str(datos.get("nombre", "")).strip()
    if not 2 <= len(nombre) <= 80:
        raise EntradaInvalida({"nombre": "Escribe tu nombre (2 a 80 caracteres)."})
    contrasena = validar_contrasena(datos.get("contrasena"))
    if User.objects.filter(username=correo).exists():
        raise EntradaInvalida({"correo": "Ya existe una cuenta con ese correo."})
    usuario = User.objects.create_user(username=correo, email=correo, password=contrasena, first_name=nombre)
    return usuario, _emitir(usuario, ip)


def iniciar_sesion(datos, ip=""):
    correo = _correo(datos)
    contrasena = str(datos.get("contrasena", ""))
    usuario = User.objects.filter(username=correo).first()
    valida = check_password(contrasena, usuario.password if usuario else _HASH_FALSO)
    if not usuario:
        raise NoAutorizado("Correo o contraseña incorrectos.")
    intentos, _ = IntentosLogin.objects.get_or_create(usuario=usuario)
    if intentos.bloqueado_hasta and intentos.bloqueado_hasta > timezone.now():
        raise NoAutorizado("Cuenta bloqueada por intentos fallidos. Intenta en unos minutos.", 423, "CUENTA_BLOQUEADA")
    if not valida:
        intentos.fallos += 1
        if intentos.fallos >= MAX_FALLOS:
            intentos.fallos, intentos.bloqueado_hasta = 0, timezone.now() + timedelta(minutes=BLOQUEO_MIN)
        intentos.save()
        raise NoAutorizado("Correo o contraseña incorrectos.")
    if not usuario.is_active:
        raise NoAutorizado("Tu cuenta está desactivada.", 403, "CUENTA_INACTIVA")
    intentos.fallos, intentos.bloqueado_hasta = 0, None
    intentos.save()
    return usuario, _emitir(usuario, ip)


def usuario_de(request):
    """Usuario dueño del encabezado `Authorization: Bearer <token>`, o None si falta, no existe o expiró."""
    cabecera = request.headers.get("Authorization", "")
    if not cabecera.startswith("Bearer "):
        return None
    sesion = Sesion.objects.select_related("usuario").filter(token_hash=_hash_token(cabecera[7:].strip()), expira__gt=timezone.now()).first()
    if not sesion or not sesion.usuario.is_active:
        return None
    return sesion.usuario


def cerrar_sesion(request):
    cabecera = request.headers.get("Authorization", "")
    if cabecera.startswith("Bearer "):
        Sesion.objects.filter(token_hash=_hash_token(cabecera[7:].strip())).delete()
