"""Asistente del negocio, organizado en 8 capas (cada una se puede probar por separado).

  1. Seguridad de entrada    -> longitud, intentos de inyección ("ignora tus instrucciones")
  2. Router                  -> modelo de intenciones entrenado + entidades (folio, marca, categoría, presupuesto)
  3. Memoria                 -> contexto corto por sesión: "¿y de Fender?", "el más barato", "ese pedido"
  4. Herramientas            -> catálogo y pedidos (datos vivos, en la base) o recuperación RAG sobre el corpus
  5. Permisos                -> roles: público (corpus público), cliente (su folio, verificado con su correo),
                                interno (documentos internos, solo con token de administrador)
  6. Respuesta con evidencia -> fuentes citadas, tarjetas de producto, sugerencias y traza de capas
  7. Observabilidad          -> cada consulta se registra (sin datos personales) con intención, latencia,
                                resultado y feedback 👍/👎; endpoint de métricas para el administrador
  8. Evaluación + humano     -> `manage.py evaluar_asistente` (casos esperados antes de cada cambio) y
                                escalamiento a una persona cuando se pide o el bot no sabe

La decisión de embalaje NUNCA se adivina aquí: se remite al recomendador o se lee lo registrado.
"""
import json
import re
import time
import unicodedata
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from .imagenes import mini_de
from .models import ConsultaAsistente, ContextoAsistente, Pedido, Producto

BASE = Path(__file__).resolve().parent
RUTA_MODELO = BASE.parent / "ml" / "modelos" / "asistente.joblib"
RUTA_CHUNKS = BASE / "corpus" / "chunks.jsonl"

UMBRAL_INTENCION = 0.30
UMBRAL_CORPUS = 0.08
RE_FOLIO = re.compile(r"MUS-\d{4}-\d{6}", re.IGNORECASE)
INYECCION = re.compile(
    r"ignora (tus|las|todas)|olvida (tus|las) instrucciones|reglas internas|contrase[nñ]a del sistema|system prompt|"
    r"act[uú]a como|eres chatgpt|muestra tu prompt",
    re.IGNORECASE,
)

RE_CORREO = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
RE_ESCALAR = re.compile(r"\b(humano|asesor|asesora|persona real|agente|supervisor|queja|hablar con alguien|quiero hablar con)\b", re.IGNORECASE)
RE_INTERNO = re.compile(r"procedimiento interno|protocolo interno|c[oó]mo (se )?atiend[ea]n? (un )?reclamo|umbrales? internos?|uso interno", re.IGNORECASE)
CONTACTO = "soporte@tesitura.local (respuesta en horario de oficina; dato de ejemplo)"


@dataclass
class Peticion:
    """Quién pregunta: sesión (memoria), correo (rol cliente) y si es administrador (rol interno)."""

    sesion: str = ""
    correo: str = ""
    admin: bool = False


INTENCIONES_CORPUS = {
    "guia_compra": ["guia_guitarras-v1", "guia_teclados-v1", "compatibilidad_accesorios-v1"],
    "envios": ["envios_instrumentos-v1"],
    "devoluciones_garantia": ["devoluciones_garantia-v1"],
    "cuidados": ["cuidados_instrumentos-v1"],
}

# palabra clave -> filtro del catálogo
CATEGORIAS_CLAVE = {
    "guitarra": {"categoria": "guitarra"}, "guitarras": {"categoria": "guitarra"},
    "bajo": {"subcategoria": "Bajos"}, "bajos": {"subcategoria": "Bajos"},
    "teclado": {"categoria": "teclado"}, "teclados": {"categoria": "teclado"},
    "piano": {"subcategoria": "Pianos digitales"}, "pianos": {"subcategoria": "Pianos digitales"},
    "sintetizador": {"subcategoria": "Sintetizadores"}, "controlador": {"subcategoria": "Controladores MIDI"},
    "midi": {"subcategoria": "Controladores MIDI"},
    "bateria": {"subcategoria": "Baterías acústicas"}, "baterias": {"subcategoria": "Baterías acústicas"},
    "platillo": {"subcategoria": "Platillos"}, "platillos": {"subcategoria": "Platillos"},
    "cajon": {"subcategoria": "Cajones"}, "cajones": {"subcategoria": "Cajones"},
    "violin": {"subcategoria": "Violines"}, "violines": {"subcategoria": "Violines"},
    "violonchelo": {"subcategoria": "Violonchelos"}, "chelo": {"subcategoria": "Violonchelos"},
    "saxofon": {"subcategoria": "Saxofones"}, "saxo": {"subcategoria": "Saxofones"},
    "flauta": {"subcategoria": "Flautas"}, "flautas": {"subcategoria": "Flautas"},
    "microfono": {"subcategoria": "Micrófonos"}, "microfonos": {"subcategoria": "Micrófonos"},
    "amplificador": {"subcategoria": "Amplificadores"}, "amplificadores": {"subcategoria": "Amplificadores"},
    "pedal": {"subcategoria": "Pedales"}, "pedales": {"subcategoria": "Pedales"},
    "cuerdas": {"subcategoria": "Cuerdas y accesorios"}, "baquetas": {"subcategoria": "Parches y baquetas"},
    "trompeta": {"subcategoria": "Trompetas"}, "trompetas": {"subcategoria": "Trompetas"},
    "clarinete": {"subcategoria": "Clarinetes"}, "clarinetes": {"subcategoria": "Clarinetes"},
    "ukelele": {"subcategoria": "Ukeleles"}, "ukeleles": {"subcategoria": "Ukeleles"},
    "audifonos": {"subcategoria": "Audífonos"}, "monitor": {"subcategoria": "Monitores de estudio"},
    "redoblante": {"subcategoria": "Redoblantes"}, "clasica": {"subcategoria": "Guitarras clásicas"},
}


def _sin_acentos(t):
    return "".join(c for c in unicodedata.normalize("NFD", t.lower()) if unicodedata.category(c) != "Mn")


@lru_cache(maxsize=1)
def _modelo():
    if not RUTA_MODELO.exists():
        raise FileNotFoundError("Falta el modelo. Ejecuta: python ml/entrenar_asistente.py")
    return joblib.load(RUTA_MODELO)


@lru_cache(maxsize=2)
def _indice(audiencia):
    """Un índice separado por audiencia: lo interno nunca entra al índice público (capa de permisos)."""
    chunks = [json.loads(l) for l in RUTA_CHUNKS.read_text(encoding="utf-8").splitlines() if l.strip()]
    chunks = [c for c in chunks if c.get("audiencia") == audiencia]
    vec = TfidfVectorizer(strip_accents="unicode", ngram_range=(1, 2))
    matriz = vec.fit_transform([c["titulo"] + " " + c["texto"] for c in chunks])
    return chunks, vec, matriz


def metricas_asistente():
    return _modelo()["metricas"]


# ---------------------------------------------------------------- capa 2: router
def clasificar(mensaje):
    pipe = _modelo()["modelo"]
    probas = pipe.predict_proba([mensaje])[0]
    i = int(probas.argmax())
    return pipe.classes_[i], float(probas[i])


def extraer_entidades(mensaje):
    texto = _sin_acentos(mensaje)
    ent = {}
    folio = RE_FOLIO.search(mensaje)
    if folio:
        ent["folio"] = folio.group(0).upper()
    marcas = []
    for marca in Producto.objects.values_list("marca", flat=True).distinct():
        m = re.sub(r"[^a-z0-9 ]", "", _sin_acentos(marca))
        patron = r"\b" + r"\s?".join(re.escape(x) for x in m.split()) + r"\b"
        if m and re.search(patron, re.sub(r"[^a-z0-9 ]", "", texto)):
            marcas.append(marca)
    if marcas:
        ent["marcas"] = marcas
    for palabra in re.findall(r"[a-z]+", texto):
        if palabra in CATEGORIAS_CLAVE:
            ent.update(CATEGORIAS_CLAVE[palabra])
            break
    m = re.search(r"(?:menos de|hasta|maximo|bajo|no mas de|por debajo de|presupuesto(?: para [a-z ]+)? (?:es )?de|cueste)\s*\$?\s*(\d[\d.,]*)\s*(mil|k)?", texto)
    if not m:
        m = re.search(r"\$\s*(\d[\d.,]*)\s*(mil|k)?", texto)
    if m:
        try:
            num = float(m.group(1).replace(",", ""))
            ent["max_precio"] = num * 1000 if m.group(2) else num
        except ValueError:
            pass
    ent["barato"] = bool(re.search(r"barat|econom|principiante|empezar|aprender|estudi", texto))
    ent["popular"] = bool(re.search(r"mas vendid|popular|mejor valorad|mejores", texto))
    return ent


# ---------------------------------------------------------------- capa 3: herramientas
def buscar_en_corpus(mensaje, ids_permitidos=None, audiencia="publica_prueba"):
    chunks, vec, matriz = _indice(audiencia)
    sims = cosine_similarity(vec.transform([mensaje]), matriz)[0]
    candidatos = [(s, c) for s, c in zip(sims, chunks) if ids_permitidos is None or c["id"] in ids_permitidos]
    if not candidatos:
        return None
    s, mejor = max(candidatos, key=lambda x: x[0])
    return (mejor, float(s)) if s >= UMBRAL_CORPUS else None


def buscar_productos(mensaje, ent, solo_ofertas=False, limite=4):
    """Busca en el catálogo con filtros estructurados; si no hay resultados, relaja el presupuesto."""
    qs = Producto.objects.all()
    if "categoria" in ent:
        qs = qs.filter(categoria=ent["categoria"])
    if "subcategoria" in ent:
        qs = qs.filter(subcategoria=ent["subcategoria"])
    if ent.get("marcas"):
        qs = qs.filter(marca__in=ent["marcas"])
    if solo_ofertas:
        qs = qs.filter(precio_original_mxn__isnull=False)
    relajado = False
    filtrado = qs.filter(precio_mxn__lte=ent["max_precio"]) if "max_precio" in ent else qs
    if "max_precio" in ent and not filtrado.exists():
        filtrado, relajado = qs, True
    lista = list(filtrado.filter(existencias__gt=0)[:200])
    if not any(k in ent for k in ("categoria", "subcategoria", "marcas")) and not solo_ofertas:
        palabras = {p.rstrip("s") for p in re.findall(r"[a-z]{4,}", _sin_acentos(mensaje))} - {"tienen", "cuanto", "cuesta", "precio", "venden", "existencia", "muestrame", "busco", "quiero", "modelos", "manejan", "opciones", "recomiendas", "recomiendan", "productos", "algo"}
        puntuados = []
        for p in lista:
            etiqueta = _sin_acentos(f"{p.nombre} {p.subcategoria} {p.marca}")
            puntos = sum(1 for w in palabras if w in etiqueta)
            if puntos:
                puntuados.append((puntos, p))
        lista = [p for _, p in sorted(puntuados, key=lambda x: (-x[0], -x[1].vendidos))]
    elif ent.get("barato"):
        lista.sort(key=lambda p: (float(p.precio_mxn), -p.rating))
    elif solo_ofertas:
        lista.sort(key=lambda p: -p.descuento_pct)
    else:
        lista.sort(key=lambda p: (-p.rating, -p.vendidos))
    return lista[:limite], relajado


def _tarjeta(p):
    return {
        "id": p.id, "nombre": p.nombre, "marca": p.marca, "categoria": p.categoria,
        "precio_mxn": float(p.precio_mxn),
        "precio_original_mxn": float(p.precio_original_mxn) if p.precio_original_mxn else None,
        "rating": p.rating, "existencias": p.existencias, "envio_gratis": p.envio_gratis,
        "imagen_url": p.imagen_url or None, "imagen_mini_url": mini_de(p.imagen_url),
    }


# ---------------------------------------------------------------- capa 5: respuesta
def adaptar_respuesta(intencion, confianza, respuesta, capas=None, sugerencias=None, fuentes=None, **extra):
    """Adapter: unifica la salida de todas las rutas al contrato JSON que consume Flutter."""
    salida = {"intencion": intencion, "confianza": round(confianza, 3), "respuesta": respuesta,
              "capas": capas or [], "sugerencias": sugerencias or [], "fuentes": fuentes or []}
    salida.update({k: v for k, v in extra.items() if v is not None})
    return salida


SUGERENCIAS = {
    "saludo": ["¿Qué ofertas tienen?", "Busco una guitarra para principiantes", "¿Cómo va mi pedido?"],
    "ver_producto": ["¿Qué embalaje necesita?", "¿Qué ofertas tienen?", "¿Cuáles son los más vendidos?"],
    "ofertas": ["Guitarras de menos de 6 mil pesos", "¿Cuáles son los más vendidos?"],
    "pedir_recomendacion": ["¿Cuánto cuesta el violín?", "¿Cómo funcionan los envíos?"],
    "consulta_folio": ["¿Por qué me salió ese embalaje?", "¿Qué hago si llega golpeado?"],
    "explicar_recomendacion": ["¿Qué hago si llega golpeado?", "¿Puedo devolverlo?"],
    "envios": ["¿Puedo devolver un instrumento?", "¿Qué ofertas tienen?"],
    "devoluciones_garantia": ["¿Cómo funcionan los envíos?", "¿Cómo cuido mi guitarra?"],
    "guia_compra": ["Guitarras para principiantes", "Pianos digitales de menos de 15 mil"],
    "cuidados": ["¿Puedo devolver un instrumento?", "¿Qué ofertas tienen?"],
    "escalado": ["¿Cómo funcionan los envíos?"],
}


def _verificar(pedido, correo):
    """Rol cliente: un folio con dueño solo se detalla a quien demuestra el correo de la compra."""
    if not pedido.compra:
        return "sin_dueno"  # cotización de prueba sin comprador: solo datos mínimos
    return "verificado" if correo and pedido.compra.correo.lower() == correo else "no_verificado"


def _con_memoria(ent, ctx, mensaje, intencion):
    """Capa de memoria: completa un seguimiento corto con lo último que se habló."""
    texto = _sin_acentos(mensaje)
    seguimiento = len(mensaje.split()) <= 7 or re.search(r"\b(y de|y los|y las|otro|otra|mas barat|mas econom|mas caro|ese|esa)\b", texto)
    usada = []
    if intencion in ("ver_producto", "ofertas") and seguimiento:
        if not any(k in ent for k in ("categoria", "subcategoria")):
            for k in ("categoria", "subcategoria"):
                if k in ctx:
                    ent[k] = ctx[k]
                    usada.append(k)
        if "marcas" not in ent and "marcas" in ctx and ("max_precio" in ent or re.search(r"barat|econom|caro", texto)):
            ent["marcas"] = ctx["marcas"]
            usada.append("marcas")
        if re.search(r"mas barat|mas econom|menos caro", texto):
            ent["barato"] = True
    if "folio" not in ent and ctx.get("ultimo_folio") and re.search(r"\b(ese|mi) (pedido|folio|envio)|por que (me salio|ese)|ese embalaje", texto):
        ent["folio"] = ctx["ultimo_folio"]
        usada.append("folio")
    return usada


def _responder(mensaje, pet, ctx):
    capas = []

    # capa 1 · seguridad
    if INYECCION.search(mensaje):
        capas.append({"capa": "seguridad", "detalle": "Se detectó un intento de cambiar mis instrucciones; bloqueado."})
        return adaptar_respuesta("fuera_dominio", 1.0, "No puedo compartir ni cambiar mis instrucciones internas. Sí puedo ayudarte con productos, pedidos, envíos y garantías.", capas, SUGERENCIAS["saludo"])
    capas.append({"capa": "seguridad", "detalle": "Mensaje válido."})

    # capa 8 · escalamiento a una persona
    if RE_ESCALAR.search(mensaje):
        capas.append({"capa": "escalamiento", "detalle": "Pidió hablar con una persona: se deriva y se registra."})
        return adaptar_respuesta("escalado", 1.0, f"Claro, te paso con una persona del equipo. Escríbenos a {CONTACTO} e indica tu folio si tienes uno.", capas, ["¿Cómo funcionan los envíos?", "¿Puedo devolver un instrumento?"])

    # capa 5 · permisos: documentos internos solo con rol interno
    if RE_INTERNO.search(mensaje):
        if not pet.admin:
            capas.append({"capa": "permisos", "detalle": "Pidió un documento interno y no tiene rol interno: acceso denegado."})
            return adaptar_respuesta("acceso_denegado", 1.0, "Esa información es interna de la tienda y no puedo compartirla. Si tu duda es sobre una compra, dame tu folio.", capas, SUGERENCIAS["saludo"])
        capas.append({"capa": "permisos", "detalle": "Rol interno verificado con token: se consulta el índice interno."})
        r = buscar_en_corpus(mensaje, None, "interna")
        if not r:
            return adaptar_respuesta("no_entendido", 0.0, "No encontré ese documento interno.", capas, abstencion=True)
        chunk, sim = r
        capas.append({"capa": "RAG", "detalle": f"Fragmento interno «{chunk['titulo']}» (similitud {sim:.2f})."})
        return adaptar_respuesta("documento_interno", sim, chunk["texto"], capas, fuentes=[{"id": chunk["id"], "titulo": chunk["titulo"], "version": chunk.get("version")}], aviso="Documento interno: no compartir con clientes.")

    # capa 2 · router
    intencion, conf = clasificar(mensaje)
    ent = extraer_entidades(mensaje)
    correo = pet.correo or (RE_CORREO.search(mensaje).group(0).lower() if RE_CORREO.search(mensaje) else "")
    # capa 3 · memoria
    usada = _con_memoria(ent, ctx, mensaje, intencion)
    if usada:
        capas.append({"capa": "memoria", "detalle": f"Seguimiento: recordé {', '.join(usada)} de la conversación."})
    if ent.get("folio") and intencion not in ("consulta_folio", "explicar_recomendacion"):
        intencion = "consulta_folio"
    if ent.get("folio") is None and "folio" in usada:
        intencion = intencion if intencion in ("consulta_folio", "explicar_recomendacion") else "explicar_recomendacion"
    if any(k in ent for k in ("marcas", "categoria", "subcategoria", "max_precio")):
        if intencion in ("fuera_dominio", "saludo", "despedida", "guia_compra") and not ent.get("folio") and conf < 0.85:
            intencion = "ver_producto"
    visibles = {k: v for k, v in ent.items() if v not in (False, None)}
    capas.append({"capa": "router", "detalle": f"Intención «{intencion}» ({conf:.0%}). Entidades: {visibles or 'ninguna'}."})

    if conf < UMBRAL_INTENCION and not ent.get("folio") and not any(k in ent for k in ("marcas", "categoria", "subcategoria")):
        return adaptar_respuesta("no_entendido", conf, "No estoy seguro de haber entendido. Puedo ayudarte con productos y ofertas, el estado de un pedido (con tu folio), envíos, garantías y cuidados. Si prefieres, escribe «quiero hablar con una persona».", capas, SUGERENCIAS["saludo"], abstencion=True)

    sug = SUGERENCIAS.get(intencion, SUGERENCIAS["saludo"])

    if intencion == "saludo":
        return adaptar_respuesta(intencion, conf, "¡Hola! Soy el asistente de Tesitura. Puedo buscar instrumentos por marca, tipo o presupuesto, mostrarte ofertas, consultar tu folio, explicarte el embalaje recomendado y resolver dudas de envíos, garantía y cuidados.", capas, sug)
    if intencion == "despedida":
        return adaptar_respuesta(intencion, conf, "¡Con gusto! Que disfrutes tu música. 🎸", capas)
    if intencion == "fuera_dominio":
        return adaptar_respuesta(intencion, conf, "Solo puedo ayudarte con temas de la tienda: instrumentos, ofertas, pedidos, envíos, garantías y cuidados. ¿Te ayudo con alguno?", capas, SUGERENCIAS["saludo"])

    if intencion in ("consulta_folio", "explicar_recomendacion"):
        if not ent.get("folio"):
            return adaptar_respuesta(intencion, conf, "Necesito tu folio para consultarlo. Tiene el formato MUS-2026-000001 y lo ves al terminar tu compra.", capas, requiere="folio")
        folio = ent["folio"]
        try:
            p = Pedido.objects.select_related("producto", "compra").get(folio=folio)
        except Pedido.DoesNotExist:
            capas.append({"capa": "herramienta: pedidos", "detalle": f"Folio {folio} no existe."})
            return adaptar_respuesta(intencion, conf, f"No encontré el folio {folio}. Revisa que esté bien escrito.", capas, folio=folio, abstencion=True)
        rol = _verificar(p, correo)
        if rol == "no_verificado":
            capas.append({"capa": "permisos", "detalle": "El folio tiene dueño y no se verificó su correo: no se revela ningún dato."})
            return adaptar_respuesta(intencion, conf, f"Encontré el folio {folio}, pero para mostrarte sus datos necesito verificar que es tuyo. Escríbeme el correo que usaste al comprar.", capas, requiere="correo", folio=folio)
        capas.append({"capa": "permisos", "detalle": {"verificado": "Correo verificado: rol cliente, se muestran los datos de su pedido.", "sin_dueno": "Cotización sin comprador: solo datos mínimos (producto, estado, embalaje)."}[rol]})
        capas.append({"capa": "herramienta: pedidos", "detalle": f"Lectura del folio {folio} en la base de datos."})
        ctx["ultimo_folio"] = folio
        nombre = p.producto.nombre if p.producto else p.tipo
        if intencion == "consulta_folio":
            texto = f"Tu pedido {p.folio} ({nombre}) está en estado «{p.estado}». Embalaje: {p.nivel_final}"
            texto += f", envío a {p.destino}." if (p.destino and rol == "verificado") else "."
        else:
            texto = f"Para {p.folio} el modelo sugirió «{p.nivel_modelo}» con {p.confianza:.0%} de confianza."
            if p.corregido:
                texto += " Las reglas lo cambiaron a «%s»: %s" % (p.nivel_final, " ".join(r["motivo"] for r in p.reglas))
            else:
                texto += f" Las reglas lo confirmaron: se queda en «{p.nivel_final}»."
            capas.append({"capa": "recomendador", "detalle": "No recalculé nada: leí la decisión ya registrada (modelo + reglas)."})
        return adaptar_respuesta(intencion, conf, texto, capas, sug, folio=p.folio, estado=p.estado, nivel_final=p.nivel_final)

    if intencion == "pedir_recomendacion":
        capas.append({"capa": "recomendador", "detalle": "Decisión de dominio: se remite al recomendador (modelo + reglas); no la calculo yo."})
        return adaptar_respuesta(intencion, conf, "El embalaje y el seguro los calcula el recomendador de la tienda, no yo. Abre un producto, elige tu ciudad (o usa tu ubicación) en «Envío protegido» y verás la recomendación al instante (y tu folio al comprar).", capas, sug, accion="abrir_recomendador")

    if intencion in ("ver_producto", "ofertas"):
        productos, relajado = buscar_productos(mensaje, ent, solo_ofertas=(intencion == "ofertas"))
        filtros = {k: v for k, v in ent.items() if k in ("categoria", "subcategoria", "marcas", "max_precio")}
        capas.append({"capa": "herramienta: catálogo", "detalle": f"Consulta a la base de datos con filtros {filtros or 'ninguno'}; {len(productos)} resultado(s)."})
        ctx.update({k: v for k, v in filtros.items() if k != "max_precio"})
        if not productos:
            return adaptar_respuesta(intencion, conf, "No encontré eso en el catálogo. Prueba con una marca (Yamaha, Fender, Roland…) o un tipo (guitarra, piano, batería, micrófono).", capas, sug, abstencion=True)
        if intencion == "ofertas":
            intro = "Estas son las mejores ofertas ahora mismo:"
        else:
            marcas_txt = " y ".join(ent["marcas"]) if ent.get("marcas") else ""
            intro = f"Encontré {len(productos)} opción(es){' de ' + marcas_txt if marcas_txt else ''}"
            if "max_precio" in ent:
                intro += f" {'(no hay nada dentro de $' + format(ent['max_precio'], ',.0f') + ', te muestro lo más cercano)' if relajado else 'hasta $' + format(ent['max_precio'], ',.0f')}"
            intro += ":"
        return adaptar_respuesta(intencion, conf, intro, capas, sug, productos=[_tarjeta(p) for p in productos])

    if intencion in INTENCIONES_CORPUS:
        capas.append({"capa": "permisos", "detalle": "El índice público solo contiene documentos con audiencia pública."})
        r = buscar_en_corpus(mensaje, set(INTENCIONES_CORPUS[intencion]))
        if not r:
            capas.append({"capa": "RAG", "detalle": "Ningún fragmento supera el umbral de similitud; me abstengo."})
            return adaptar_respuesta(intencion, conf, "No tengo una fuente confiable para eso. Si quieres, escribe «quiero hablar con una persona».", capas, sug, abstencion=True)
        chunk, sim = r
        capas.append({"capa": "RAG", "detalle": f"Fragmento «{chunk['titulo']}» (similitud {sim:.2f})."})
        aviso = "Información de muestra académica, no condición real de venta." if chunk.get("estado") == "simulacion_academica" else None
        return adaptar_respuesta(intencion, conf, chunk["texto"], capas, sug, fuentes=[{"id": chunk["id"], "titulo": chunk["titulo"], "version": chunk.get("version")}], aviso=aviso)

    return adaptar_respuesta("no_entendido", conf, "No tengo respuesta para eso todavía.", capas, SUGERENCIAS["saludo"], abstencion=True)


def _resultado(r):
    if r["intencion"] == "escalado":
        return "escalado"
    if any(c["capa"] == "seguridad" and "bloqueado" in c["detalle"] for c in r["capas"]) or r["intencion"] == "acceso_denegado":
        return "bloqueado"
    return "abstencion" if r.pop("abstencion", False) else "ok"


def responder(mensaje, pet=None):
    """Punto de entrada: carga la memoria, responde, registra la consulta y guarda la memoria."""
    pet = pet or Peticion()
    mensaje = (mensaje or "").strip()
    if not mensaje:
        return adaptar_respuesta("vacio", 0.0, "Escribe tu pregunta y con gusto te ayudo.")
    inicio = time.perf_counter()
    memoria = ContextoAsistente.objects.filter(sesion=pet.sesion).first() if pet.sesion else None
    ctx = dict(memoria.datos) if memoria else {}
    r = _responder(mensaje, pet, ctx)
    resultado = _resultado(r)
    ms = int((time.perf_counter() - inicio) * 1000)
    try:  # capa 7 · observabilidad: nunca rompe la respuesta
        if pet.sesion:
            ContextoAsistente.objects.update_or_create(sesion=pet.sesion, defaults={"datos": ctx})
        c = ConsultaAsistente.objects.create(
            sesion=pet.sesion, mensaje=RE_CORREO.sub("[correo]", mensaje)[:300], intencion=r["intencion"], confianza=r["confianza"],
            latencia_ms=ms, resultado=resultado, capas=r["capas"])
        r["consulta_id"] = c.id
        r["capas"].append({"capa": "observabilidad", "detalle": f"Consulta #{c.id} registrada: {resultado}, {ms} ms (sin datos personales)."})
    except Exception:  # noqa: BLE001
        pass
    return r
