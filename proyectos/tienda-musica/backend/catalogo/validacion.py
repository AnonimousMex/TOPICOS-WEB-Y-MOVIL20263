from datetime import date

from .models import Producto

TIPOS = [c for c, _ in Producto.CATEGORIAS]
NIVEL3 = ("baja", "media", "alta")


class EntradaInvalida(Exception):
    def __init__(self, errores):
        self.errores = errores


def temporada_actual(hoy=None):
    """Lluvias de junio a octubre (aproximación para México)."""
    return "lluvias" if 6 <= (hoy or date.today()).month <= 10 else "secas"


def _numero(datos, campo, minimo, maximo, errores, entero=False):
    try:
        valor = float(datos[campo])
    except (KeyError, TypeError, ValueError):
        errores[campo] = "Es obligatorio y debe ser numérico."
        return None
    if not (minimo <= valor <= maximo):
        errores[campo] = f"Debe estar entre {minimo} y {maximo}."
        return None
    return int(valor) if entero else valor


def _opcion(datos, campo, opciones, defecto, errores):
    valor = datos.get(campo, defecto)
    if valor not in opciones:
        errores[campo] = f"Debe ser uno de: {', '.join(opciones)}."
        return None
    return valor


def validar_envio(datos):
    """Valida el JSON del cliente. El servidor NUNCA confía en la validación de Flutter.

    Decisión sobre datos faltantes (pregunta del curso): los campos del instrumento (tipo, valor, peso,
    dimensión, distancia) son OBLIGATORIOS y el endpoint rechaza con 400 en lugar de inventarlos; el
    imputador del pipeline solo protege el entrenamiento. Las condiciones del destino tienen valor por defecto.
    """
    errores = {}
    tipo = datos.get("tipo")
    if tipo not in TIPOS:
        errores["tipo"] = f"Debe ser uno de: {', '.join(TIPOS)}."
    limpio = {
        "tipo": tipo,
        "condicion": _opcion(datos, "condicion", ("nuevo", "usado"), "nuevo", errores),
        "valor_mxn": _numero(datos, "valor_mxn", 1, 400000, errores),
        "peso_kg": _numero(datos, "peso_kg", 0.05, 200, errores),
        "dimension_max_cm": _numero(datos, "dimension_max_cm", 5, 300, errores, entero=True),
        "distancia_km": _numero(datos, "distancia_km", 1, 5000, errores, entero=True),
        "fragil": bool(datos.get("fragil", True)),
        "cantidad": 1,
        "humedad_destino": _opcion(datos, "humedad_destino", NIVEL3, "media", errores),
        "zona_riesgo": _opcion(datos, "zona_riesgo", NIVEL3, "baja", errores),
        "temporada": _opcion(datos, "temporada", ("secas", "lluvias"), temporada_actual(), errores),
        "urgente": bool(datos.get("urgente", False)),
    }
    if "cantidad" in datos:
        limpio["cantidad"] = _numero(datos, "cantidad", 1, 10, errores, entero=True)
    if errores:
        raise EntradaInvalida(errores)
    return limpio
