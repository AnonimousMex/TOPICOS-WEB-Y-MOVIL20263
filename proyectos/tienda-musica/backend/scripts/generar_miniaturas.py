"""Genera miniaturas (lado mayor 360 px) de las fotos de producto para las tarjetas y el chat.

Las tarjetas muestran la foto a ~170 px: bajar y decodificar la foto completa en cada una vuelve lento el
desplazamiento (sobre todo en pantallas Retina). La ficha del producto sigue usando la foto completa.

Uso (desde backend/):  python scripts/generar_miniaturas.py
Usa `sips` (macOS) o Pillow si está instalado.
"""
import shutil
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent / "catalogo" / "static"
ORIGEN, DESTINO, LADO = RAIZ / "productos", RAIZ / "productos_mini", 360


def con_pillow(origen, destino):
    from PIL import Image

    with Image.open(origen) as im:
        im.thumbnail((LADO, LADO))
        im.convert("RGB").save(destino, "JPEG", quality=78, optimize=True)


def con_sips(origen, destino):
    subprocess.run(["sips", "-Z", str(LADO), "-s", "format", "jpeg", "-s", "formatOptions", "78", str(origen), "--out", str(destino)], check=True, capture_output=True)


def main():
    DESTINO.mkdir(exist_ok=True)
    try:
        import PIL  # noqa: F401
        convertir = con_pillow
    except ImportError:
        if not shutil.which("sips"):
            raise SystemExit("Instala Pillow (pip install pillow) o usa macOS (sips).")
        convertir = con_sips
    hechas = 0
    for f in sorted(ORIGEN.iterdir()):
        if f.suffix.lower() in (".jpg", ".jpeg", ".png"):
            salida = DESTINO / (f.stem + ".jpg")
            if not salida.exists():
                convertir(f, salida)
                hechas += 1
    total = sum(1 for _ in DESTINO.iterdir())
    kb = sum(f.stat().st_size for f in DESTINO.iterdir()) / 1024
    print(f"{hechas} nuevas · {total} miniaturas · {kb:,.0f} KB en total (promedio {kb / max(total, 1):.0f} KB)")


if __name__ == "__main__":
    main()
