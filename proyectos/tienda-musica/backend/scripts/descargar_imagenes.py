"""Descarga fotos de productos y logos de marcas desde Wikimedia Commons (licencias libres).

Uso (desde backend/):  python scripts/descargar_imagenes.py
Salida: catalogo/static/productos/*, catalogo/static/marcas/*, catalogo/imagenes.json

Reglas:
  * Solo se aceptan CC BY, CC BY-SA, CC0, dominio público y GFDL (nada NC/ND).
  * Cada imagen guarda autor, licencia y enlace a su página: la tienda los muestra.
  * Producto: 1) foto del modelo exacto; 2) foto de la marca y del tipo de instrumento;
    3) foto de referencia del tipo de instrumento. El nivel queda en `nivel` para ser honestos en la UI.
  * Logos: solo si Commons tiene uno con licencia aceptable; si no, la app dibuja el nombre de la marca.
Es idempotente: reutiliza lo ya descargado. Marcas y logos son de sus dueños (uso solo identificativo).
"""
import json
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))
from catalogo.datos_catalogo import PRODUCTOS  # noqa: E402

API = "https://commons.wikimedia.org/w/api.php"
UA = "TiendaMusicaEscolar/1.0 (proyecto academico de la materia Topicos Web y Movil)"
DIR_PROD = RAIZ / "catalogo" / "static" / "productos"
DIR_MARC = RAIZ / "catalogo" / "static" / "marcas"
SALIDA = RAIZ / "catalogo" / "imagenes.json"
MANUAL = RAIZ / "scripts" / "imagenes_manual.json"  # {"productos": {nombre: titulo_commons|null}, "marcas": {...}}

INGLES = {
    "Guitarras acústicas": "acoustic guitar", "Guitarras eléctricas": "electric guitar", "Bajos": "bass guitar",
    "Pianos digitales": "digital piano", "Teclados": "electronic keyboard", "Controladores MIDI": "MIDI controller",
    "Sintetizadores": "synthesizer", "Saxofones": "saxophone", "Flautas": "flute", "Baterías acústicas": "drum kit",
    "Baterías electrónicas": "electronic drum kit", "Platillos": "cymbal", "Cajones": "cajon", "Parches y baquetas": "drumsticks",
    "Violines": "violin", "Violonchelos": "cello", "Amplificadores": "guitar amplifier", "Pedales": "guitar effects pedal",
    "Micrófonos": "microphone", "Interfaces y mezcladoras": "audio mixer", "Cuerdas y accesorios": "guitar strings",
    "Guitarras clásicas": "classical guitar", "Ukeleles": "ukulele", "Trompetas": "trumpet", "Clarinetes": "clarinet",
    "Redoblantes": "snare drum", "Audífonos": "headphones", "Monitores de estudio": "studio monitor",
    "Atriles y soportes": "bass drum pedal",
}
CLAVES = {  # palabras que debe contener el título para que la foto sea del tipo correcto
    "Guitarras acústicas": ["guitar"], "Guitarras eléctricas": ["guitar", "stratocaster", "telecaster", "les paul", "sg"],
    "Bajos": ["bass"], "Pianos digitales": ["piano", "keyboard"], "Teclados": ["keyboard", "piano", "psr", "ct-"],
    "Controladores MIDI": ["midi", "controller", "keyboard", "pad"], "Sintetizadores": ["synth", "keyboard", "minilogue", "freak"],
    "Saxofones": ["sax"], "Flautas": ["flute"], "Baterías acústicas": ["drum", "kit"], "Baterías electrónicas": ["drum", "kit"],
    "Platillos": ["cymbal", "hi-hat", "hihat", "ride", "crash"], "Cajones": ["cajon", "cajón"], "Parches y baquetas": ["drum", "stick", "head"],
    "Violines": ["violin"], "Violonchelos": ["cello"], "Amplificadores": ["amp"], "Pedales": ["pedal", "effect", "overdrive", "delay", "distortion"],
    "Micrófonos": ["mic", "sm58", "sm57", "sm7"], "Interfaces y mezcladoras": ["mixer", "interface", "mixing"],
    "Cuerdas y accesorios": ["string", "tuner", "strap", "capo"], "Guitarras clásicas": ["guitar", "classical"], "Ukeleles": ["ukulele", "ukelele"],
    "Trompetas": ["trumpet"], "Clarinetes": ["clarinet"], "Redoblantes": ["snare"], "Audífonos": ["headphone"],
    "Monitores de estudio": ["monitor", "speaker"], "Atriles y soportes": ["pedal", "throne", "stool", "drum"],
}
EXCLUIR = re.compile(r"concert|live|festival|band|crowd|tour|jam|perform|quartet|orchestra|museum|factory|store|shop|poster|stamp|"
                     r"guitarist|drummer|pianist|musician|singer|girl|boy|woman|\bman\b|child|kid|people|group|stage|show|"
                     r"drawing|diagram|schematic|patent|repair|workshop|exhibition|fair|namm|sketch", re.I)
GENERICAS = {"player", "standard", "custom", "series", "special", "classic", "guitarra", "electrica", "acustica", "bajo", "teclado", "piano", "digital", "pedal", "amplificador", "microfono", "audifonos", "cuerdas", "baqueta", "bateria", "platillo", "cajon", "controlador", "midi", "sintetizador", "monitor", "estudio", "saxofon", "flauta", "trompeta", "clarinete", "violin", "violonchelo", "ukelele", "redoblante", "correa", "afinador", "parche", "interfaz", "mezcladora", "pedalera", "banco", "hihat", "hi-hat", "ride", "crash", "pad", "controlador"}
ALIAS_LOGO = {
    "DW": "DW Drums logo", "PRS": "PRS Guitars logo", "Pearl": "Pearl Drums logo", "Orange": "Orange Amplification logo",
    "Marshall": "Marshall Amplification logo", "Vox": "Vox amplification logo", "Remo": "Remo drumheads logo", "Boss": "Boss Corporation logo",
    "Tama": "Tama Drums logo", "Nord": "Nord Keyboards logo", "Taylor": "Taylor Guitars logo", "Martin": "Martin Guitar logo",
    "Selmer": "Selmer Paris logo", "Jupiter": "Jupiter Band Instruments logo", "Elixir": "Elixir Strings logo", "Ludwig": "Ludwig Drums logo",
    "Jackson": "Jackson Guitars logo", "ESP": "ESP Guitars logo", "Schecter": "Schecter Guitar Research logo", "Line 6": "Line 6 logo",
    "Mapex": "Mapex Drums logo", "Meinl": "Meinl Percussion logo", "Sabian": "Sabian cymbals logo", "Zildjian": "Zildjian logo",
}
PERMITIDA = re.compile(r"^(CC[ -]BY(-SA)?[ -][\d.]+|CC0|Public domain|PD|GFDL)", re.I)
PROHIBIDA = re.compile(r"\bNC\b|\bND\b|-NC|-ND", re.I)
ultimo = [0.0]


def norm(t):
    t = "".join(c for c in unicodedata.normalize("NFD", t.lower()) if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", " ", t).strip()


def plano(t):
    return norm(t).replace(" ", "")


def pedir(url, binario=False, intentos=4):
    for i in range(intentos):
        espera = 0.6 - (time.time() - ultimo[0])
        if espera > 0:
            time.sleep(espera)
        ultimo[0] = time.time()
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=30) as r:
                datos = r.read()
                return datos if binario else json.loads(datos)
        except Exception as e:  # noqa: BLE001
            if i == intentos - 1:
                print("   ! fallo", url[:90], e)
                return None
            time.sleep(2 + 3 * i)


def commons(consulta, ancho, limite=15):
    params = {"action": "query", "format": "json", "generator": "search", "gsrnamespace": 6, "gsrlimit": limite, "gsrsearch": consulta,
              "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata", "iiurlwidth": ancho}
    return _parsear(pedir(API + "?" + urllib.parse.urlencode(params)))


def por_titulo(titulo, ancho):
    """Archivo exacto de Commons (elegido a mano tras revisarlo)."""
    params = {"action": "query", "format": "json", "titles": "File:" + titulo, "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata", "iiurlwidth": ancho}
    r = _parsear(pedir(API + "?" + urllib.parse.urlencode(params)))
    return r[0] if r else None


def _parsear(d):
    if not d or "query" not in d:
        return []
    salida = []
    for p in sorted(d["query"]["pages"].values(), key=lambda x: x.get("index", 0)):
        ii = (p.get("imageinfo") or [{}])[0]
        meta = ii.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "")
        if not ii or not PERMITIDA.match(lic) or PROHIBIDA.search(lic):
            continue
        salida.append({
            "titulo": p["title"].replace("File:", ""), "thumb": ii.get("thumburl") or ii.get("url"), "mime": ii.get("mime", ""),
            "ancho": ii.get("width", 0), "alto": ii.get("height", 0), "licencia": lic,
            "autor": re.sub(r"<[^>]+>", "", meta.get("Artist", {}).get("value", "Autor desconocido")).strip()[:120],
            "fuente": ii.get("descriptionurl", ""),
        })
    return salida


def descargar(c, carpeta, prefijo):
    ext = Path(urllib.parse.urlparse(c["thumb"]).path).suffix.lower() or ".jpg"
    if ext not in (".jpg", ".jpeg", ".png"):
        ext = ".jpg"
    nombre = f"{prefijo}{re.sub(r'[^a-z0-9]+', '-', norm(c['titulo']))[:60].strip('-')}{ext}"
    destino = carpeta / nombre
    if not destino.exists():
        datos = pedir(c["thumb"], binario=True)
        if not datos:
            return None
        destino.write_bytes(datos)
    return nombre


def nucleo(marca, nombre):
    palabras = nombre.split()
    mm = plano(marca.split()[0])
    for i, w in enumerate(palabras):
        if plano(w).startswith(mm):
            return " ".join(palabras[i:])
    return nombre


def tokens_modelo(marca, nombre):
    sobrantes = set(norm(marca).split())
    t = []
    for w in norm(nucleo(marca, nombre)).split():
        if w in sobrantes or w in GENERICAS:
            continue
        if any(ch.isdigit() for ch in w) or len(w) >= 6:
            t.append(w)
    return t


def aceptable(c, minimo=480):
    if EXCLUIR.search(c["titulo"]) or c["mime"] not in ("image/jpeg", "image/png"):
        return False
    return c["ancho"] >= minimo and c["alto"] >= 300 and 0.5 <= c["ancho"] / max(c["alto"], 1) <= 2.4


def main():
    prev = json.loads(SALIDA.read_text()) if SALIDA.exists() else {"productos": {}, "marcas": {}}
    manual = json.loads(MANUAL.read_text()) if MANUAL.exists() else {"productos": {}, "marcas": {}}
    res = {"productos": dict(prev.get("productos", {})), "marcas": dict(prev.get("marcas", {}))}
    genericas, usos = {}, {}

    # ---- logos
    marcas = sorted({p[0] for p in PRODUCTOS})
    for m in marcas:
        fijo = manual["marcas"].get(m)
        if isinstance(fijo, str):
            if res["marcas"].get(m, {}).get("titulo") != fijo:
                c = por_titulo(fijo, 360)
                arch = descargar(c, DIR_MARC, "") if c else None
                if arch:
                    res["marcas"][m] = {"archivo": arch, **{k: c[k] for k in ("titulo", "autor", "licencia", "fuente")}}
                    print("LOGO fijo ", m, "→", c["titulo"])
                else:
                    res["marcas"].pop(m, None)
                SALIDA.write_text(json.dumps(res, ensure_ascii=False, indent=1))
            continue
        if m in res["marcas"] or fijo is None and m in manual["marcas"]:
            continue
        consultas = [ALIAS_LOGO.get(m, f"{m} logo")]
        if m not in ALIAS_LOGO:
            consultas.append(f"{m} logo filetype:drawing")
        elegido = None
        for q in consultas:
            for c in commons(q, 360):
                t = plano(c["titulo"])
                if plano(m.split()[0]) in t and "logo" in t and c["ancho"] >= 80:
                    elegido = c
                    break
            if elegido:
                break
        if elegido:
            arch = descargar(elegido, DIR_MARC, "")
            if arch:
                res["marcas"][m] = {"archivo": arch, **{k: elegido[k] for k in ("titulo", "autor", "licencia", "fuente")}}
        print(("LOGO ok   " if m in res["marcas"] else "LOGO falta"), m, "→", res["marcas"].get(m, {}).get("titulo", ""))
        SALIDA.write_text(json.dumps(res, ensure_ascii=False, indent=1))

    # ---- fotos de producto
    for marca, nombre, sub, _ in PRODUCTOS:
        fijo = manual["productos"].get(nombre)
        if isinstance(fijo, str):
            if res["productos"].get(nombre, {}).get("titulo") != fijo:
                c = por_titulo(fijo, 520)
                arch = descargar(c, DIR_PROD, "") if c else None
                if arch:
                    res["productos"][nombre] = {"archivo": arch, "nivel": manual.get("niveles", {}).get(nombre, "modelo"), **{k: c[k] for k in ("titulo", "autor", "licencia", "fuente")}}
                    print("FOTO fija ", nombre, "→", c["titulo"])
                SALIDA.write_text(json.dumps(res, ensure_ascii=False, indent=1))
            continue
        if nombre in manual["productos"] and fijo is None:
            res["productos"].pop(nombre, None)  # descartada tras revisarla: la tienda usa el visual generado
            continue
        if nombre in res["productos"]:
            continue
        elegido, nivel = None, None
        core = nucleo(marca, nombre)
        toks = tokens_modelo(marca, nombre)
        # 1) modelo exacto
        for c in commons(f"{core} filetype:bitmap", 520):
            t = plano(c["titulo"])
            if aceptable(c) and plano(marca.split()[0]) in t and any(tok.replace(" ", "") in t for tok in toks) and any(k in norm(c["titulo"]) for k in CLAVES[sub] + ["guitar", "piano", "drum", "synth"]):
                elegido, nivel = c, "modelo"
                break
        # 2) marca + tipo
        if not elegido:
            for c in commons(f"{marca} {INGLES[sub]} filetype:bitmap", 520):
                t = norm(c["titulo"])
                if aceptable(c) and plano(marca.split()[0]) in plano(c["titulo"]) and any(k in t for k in CLAVES[sub]):
                    elegido, nivel = c, "marca"
                    break
        # 3) referencia del tipo de instrumento (varias fotos por tipo, en rotación)
        if not elegido:
            if sub not in genericas:
                genericas[sub] = [c for c in commons(f"{INGLES[sub]} filetype:bitmap", 520, 30) if aceptable(c) and any(k in norm(c["titulo"]) for k in CLAVES[sub])][:8]
            if genericas[sub]:
                i = usos.get(sub, 0)
                usos[sub] = i + 1
                elegido, nivel = genericas[sub][i % len(genericas[sub])], "referencia"
        if elegido:
            arch = descargar(elegido, DIR_PROD, "")
            if arch:
                res["productos"][nombre] = {"archivo": arch, "nivel": nivel, **{k: elegido[k] for k in ("titulo", "autor", "licencia", "fuente")}}
        print(f"FOTO {nivel or 'falta':<10}", nombre, "→", (elegido or {}).get("titulo", ""))
        SALIDA.write_text(json.dumps(res, ensure_ascii=False, indent=1))
    SALIDA.write_text(json.dumps(res, ensure_ascii=False, indent=1))
    print("\nlistos:", len(res["productos"]), "fotos,", len(res["marcas"]), "logos")


if __name__ == "__main__":
    main()
