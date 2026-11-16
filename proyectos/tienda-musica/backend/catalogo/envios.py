"""Arma las entradas del recomendador a partir de un producto del catálogo.

Las medidas salen de la base de datos, no del cliente: así nadie puede pedir un
embalaje barato declarando que su piano de 60 mil pesos vale 100.
"""
from .datos_catalogo import CIUDADES
from .geo import en_cobertura, resolver_ubicacion
from .validacion import EntradaInvalida, temporada_actual


def _coordenada(datos, campo):
    try:
        return float(datos[campo])
    except (KeyError, TypeError, ValueError):
        return None


def resolver_destino(datos):
    """Devuelve (nombre, km, humedad, zona, lat_aprox, lon_aprox) para una ciudad o para «ubicacion»."""
    destino = datos.get("destino")
    if destino == "ubicacion":
        lat, lon = _coordenada(datos, "lat"), _coordenada(datos, "lon")
        if lat is None or lon is None:
            raise EntradaInvalida({"destino": "Falta la ubicación (lat y lon)."})
        if not en_cobertura(lat, lon):
            raise EntradaInvalida({"destino": "Tu ubicación está fuera de la zona de cobertura (México)."})
        r = resolver_ubicacion(lat, lon)
        return f"Mi ubicación (cerca de {r['ciudad_cercana']})", r["km_bodega"], r["humedad"], r["zona"], round(lat, 2), round(lon, 2)
    if destino not in CIUDADES:
        raise EntradaInvalida({"destino": "Elige una ciudad de la lista o usa tu ubicación."})
    c = CIUDADES[destino]
    return destino, c["km"], c["humedad"], c["zona"], None, None


def entradas_desde_producto(producto, datos):
    """datos: {cantidad, destino, lat, lon, urgente}. Devuelve (entradas, cantidad, destino, lat, lon)."""
    errores = {}
    try:
        cantidad = int(datos.get("cantidad", 1))
    except (TypeError, ValueError):
        cantidad = 0
    if not 1 <= cantidad <= 10:
        errores["cantidad"] = "Debe estar entre 1 y 10."
    try:
        nombre, km, humedad, zona, lat, lon = resolver_destino(datos)
    except EntradaInvalida as e:
        errores.update(e.errores)
    if errores:
        raise EntradaInvalida(errores)
    return {
        "tipo": producto.categoria, "condicion": "nuevo",
        "valor_mxn": float(producto.precio_mxn) * cantidad, "peso_kg": float(producto.peso_kg) * cantidad,
        "dimension_max_cm": producto.dimension_max_cm, "distancia_km": km, "fragil": producto.fragil,
        "cantidad": cantidad, "humedad_destino": humedad, "zona_riesgo": zona,
        "temporada": temporada_actual(), "urgente": bool(datos.get("urgente", False)),
    }, cantidad, nombre, lat, lon
