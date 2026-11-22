"""Middleware de auditoría: registra quién llamó a qué ruta y qué respondió el servidor.

Igual que en Rumbo, no se guarda cada lectura: solo escrituras (POST), errores (>= 400) y consultas de bitácora.
Nunca se guarda el cuerpo de la petición (ahí viajan contraseñas y tarjetas).
"""
import secrets
import time

from .autenticacion import rol_de, usuario_de
from .models import Auditoria


class AuditoriaMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        inicio = time.monotonic()
        request_id = secrets.token_hex(4)
        response = self.get_response(request)
        response["X-Request-Id"] = request_id
        if request.path.startswith("/api/") and request.method != "OPTIONS" and (
            request.method != "GET" or response.status_code >= 400 or request.path.startswith("/api/auditoria")
        ):
            try:
                usuario = usuario_de(request)
                Auditoria.objects.create(
                    request_id=request_id, usuario=usuario.email if usuario else "", rol=rol_de(usuario) if usuario else "",
                    metodo=request.method, ruta=request.path[:200], status=response.status_code,
                    ip=(request.META.get("REMOTE_ADDR") or "")[:45], duracion_ms=round((time.monotonic() - inicio) * 1000),
                )
            except Exception:  # noqa: BLE001  (la bitácora nunca debe tumbar una respuesta)
                pass
        return response
