"""Genera ../CREDITOS_IMAGENES.md con autor, licencia y fuente de cada foto y logo.
Uso (desde backend/): python scripts/generar_creditos.py"""
import json
from pathlib import Path

raiz = Path(__file__).resolve().parent.parent
datos = json.loads((raiz / "catalogo" / "imagenes.json").read_text(encoding="utf-8"))
niveles = {"modelo": "foto del modelo", "marca": "foto de la marca y tipo", "referencia": "foto de referencia del tipo de instrumento"}

L = ["# Créditos de imágenes", "",
     "Las fotos y logos de la tienda provienen de **Wikimedia Commons** y se usan bajo sus licencias (CC BY, CC BY-SA, CC0 o dominio público).",
     "Las marcas y logotipos pertenecen a sus dueños y se muestran solo para identificar los productos en esta práctica académica.",
     "Cuando no hay foto del modelo exacto se usa una **foto de referencia del tipo de instrumento**, y la tienda lo indica.", "",
     f"## Logos de marcas ({len(datos['marcas'])})", "", "| Marca | Archivo | Autor | Licencia | Fuente |", "|---|---|---|---|---|"]
for m, f in sorted(datos["marcas"].items()):
    L.append(f"| {m} | {f['titulo']} | {f['autor']} | {f['licencia']} | [Commons]({f['fuente']}) |")
L += ["", f"## Fotos de productos ({len(datos['productos'])})", "", "| Producto | Tipo de foto | Archivo | Autor | Licencia | Fuente |", "|---|---|---|---|---|---|"]
for n, f in sorted(datos["productos"].items()):
    L.append(f"| {n} | {niveles.get(f['nivel'], f['nivel'])} | {f['titulo']} | {f['autor']} | {f['licencia']} | [Commons]({f['fuente']}) |")
(raiz.parent / "CREDITOS_IMAGENES.md").write_text("\n".join(L) + "\n", encoding="utf-8")
print("CREDITOS_IMAGENES.md escrito")
