"""Middleware mínimo de CORS para que Flutter web (otro puerto) pueda llamar a la API."""
from django.http import HttpResponse


class CorsMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.method == "OPTIONS":
            response = HttpResponse(status=204)
        else:
            response = self.get_response(request)
        if request.path.startswith("/img/") and response.status_code == 200:
            response["Cache-Control"] = "public, max-age=86400"  # las fotos no cambian: no volver a pedirlas al desplazarse
        response["Access-Control-Allow-Origin"] = "*"
        response["Access-Control-Allow-Headers"] = "Content-Type, X-Tesitura-Token"
        response["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        return response
