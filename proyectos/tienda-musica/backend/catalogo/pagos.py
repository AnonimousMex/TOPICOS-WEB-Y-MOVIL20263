"""Pasarela de pago SIMULADA (no mueve dinero).

Reglas de seguridad de esta práctica:
  * Solo se aceptan TARJETAS DE PRUEBA (como el modo de pruebas de Stripe). Un número real se rechaza,
    para que nadie acostumbre a escribir tarjetas reales en una demostración.
  * El número completo y el CVV se validan y se descartan: nunca se guardan ni se escriben en logs.
    Solo se conserva la marca y los últimos 4 dígitos.
"""
import re
import secrets
from datetime import date


class PagoInvalido(Exception):
    def __init__(self, campos):
        self.campos = campos


class PagoRechazado(Exception):
    def __init__(self, mensaje):
        self.mensaje = mensaje


TARJETAS_DE_PRUEBA = {
    "4242424242424242": ("visa", None),
    "5555555555554444": ("mastercard", None),
    "378282246310005": ("amex", None),
    "4000000000000002": ("visa", "Tu banco rechazó la tarjeta (tarjeta de prueba de rechazo)."),
    "4000000000009995": ("visa", "Fondos insuficientes (tarjeta de prueba)."),
}


def luhn(numero):
    suma = 0
    for i, d in enumerate(reversed(numero)):
        n = int(d)
        if i % 2:
            n = n * 2 - 9 if n > 4 else n * 2
        suma += n
    return suma % 10 == 0


def detectar_marca(numero):
    if re.match(r"^3[47]", numero):
        return "amex"
    if re.match(r"^(5[1-5]|2(2[2-9]|[3-6]\d|7[01]|720))", numero):
        return "mastercard"
    if numero.startswith("4"):
        return "visa"
    return "desconocida"


def _vencimiento(texto):
    m = re.match(r"^\s*(\d{1,2})\s*[/-]\s*(\d{2}|\d{4})\s*$", str(texto or ""))
    if not m:
        return None
    mes, anio = int(m.group(1)), int(m.group(2))
    anio += 2000 if anio < 100 else 0
    return (anio, mes) if 1 <= mes <= 12 else None


def validar_tarjeta(t, hoy=None):
    """Valida el formulario. Devuelve (numero_limpio, marca) o lanza PagoInvalido con los campos que fallan."""
    hoy = hoy or date.today()
    if not isinstance(t, dict):
        raise PagoInvalido({"tarjeta": "Faltan los datos de la tarjeta."})
    errores = {}
    numero = re.sub(r"[\s-]", "", str(t.get("numero", "")))
    marca = detectar_marca(numero)
    if not numero.isdigit() or not 13 <= len(numero) <= 19 or not luhn(numero):
        errores["numero"] = "Número de tarjeta inválido."
    elif numero not in TARJETAS_DE_PRUEBA:
        errores["numero"] = "Modo de pruebas: usa 4242 4242 4242 4242. No ingreses tarjetas reales."
    if len(str(t.get("titular", "")).strip()) < 3:
        errores["titular"] = "Escribe el nombre del titular."
    venc = _vencimiento(t.get("vencimiento"))
    if not venc:
        errores["vencimiento"] = "Usa el formato MM/AA."
    elif (venc[0], venc[1]) < (hoy.year, hoy.month):
        errores["vencimiento"] = "La tarjeta está vencida."
    cvv = str(t.get("cvv", ""))
    if not cvv.isdigit() or len(cvv) != (4 if marca == "amex" else 3):
        errores["cvv"] = f"El CVV debe tener {4 if marca == 'amex' else 3} dígitos."
    if errores:
        raise PagoInvalido(errores)
    return numero, marca


def cobrar(numero, marca, monto):
    """Simula el cargo. Devuelve el resultado SIN el número completo."""
    _, rechazo = TARJETAS_DE_PRUEBA[numero]
    if rechazo:
        raise PagoRechazado(rechazo)
    return {"estado": "aprobado", "marca": marca, "ultimos4": numero[-4:], "referencia": "PAY-" + secrets.token_hex(4).upper(), "monto": float(monto)}
