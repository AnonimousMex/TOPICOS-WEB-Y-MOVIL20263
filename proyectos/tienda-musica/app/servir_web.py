"""Sirve la web compilada sin caché (evita que Chrome muestre una versión vieja).

Uso:  python servir_web.py [puerto] [--carpeta build/web] [--aislado]

--aislado agrega los encabezados COOP/COEP (aislamiento de origen cruzado). Con ellos, la versión WebAssembly
(`flutter build web --wasm`) puede usar varios hilos para dibujar y se ve más fluida. Las imágenes del backend
(otro puerto) siguen cargando porque COEP es «credentialless».
"""
import argparse
import functools
import http.server

ap = argparse.ArgumentParser()
ap.add_argument("puerto", nargs="?", type=int, default=8080)
ap.add_argument("--carpeta", default="build/web")
ap.add_argument("--aislado", action="store_true")
a = ap.parse_args()


class Manejador(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        if a.aislado:
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "credentialless")
        super().end_headers()


http.server.ThreadingHTTPServer(("", a.puerto), functools.partial(Manejador, directory=a.carpeta)).serve_forever()
