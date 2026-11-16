"""Acceso a las imágenes descargadas (fotos de producto y logos de marca)."""
import json
from functools import lru_cache
from pathlib import Path

RUTA = Path(__file__).resolve().parent / "imagenes.json"


@lru_cache(maxsize=1)
def _datos():
    return json.loads(RUTA.read_text(encoding="utf-8")) if RUTA.exists() else {"productos": {}, "marcas": {}}


def foto_de(nombre):
    """Devuelve (ruta, crédito, fuente, nivel) o None."""
    f = _datos()["productos"].get(nombre)
    if not f:
        return None
    return f"/img/productos/{f['archivo']}", f"Foto: {f['autor']} · {f['licencia']}", f["fuente"], f["nivel"]


def logo_de(marca):
    m = _datos()["marcas"].get(marca)
    return f"/img/marcas/{m['archivo']}" if m else None


def mini_de(ruta):
    """Ruta de la miniatura (360 px) de una foto /img/productos/x.jpg → /img/productos_mini/x.jpg."""
    if not ruta or not ruta.startswith("/img/productos/"):
        return None
    return "/img/productos_mini/" + ruta.rsplit("/", 1)[-1].rsplit(".", 1)[0] + ".jpg"
