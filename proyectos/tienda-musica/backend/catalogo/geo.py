"""Geografía simple y sin servicios externos: la ubicación del usuario nunca sale del servidor."""
from math import asin, cos, radians, sin, sqrt

from .datos_catalogo import BODEGA, CIUDADES, COBERTURA

FACTOR_RUTA = 1.25  # la ruta por carretera es más larga que la línea recta


def haversine_km(lat1, lon1, lat2, lon2):
    f1, f2 = radians(lat1), radians(lat2)
    a = sin((f2 - f1) / 2) ** 2 + cos(f1) * cos(f2) * sin(radians(lon2 - lon1) / 2) ** 2
    return 2 * 6371 * asin(sqrt(a))


def en_cobertura(lat, lon):
    return COBERTURA["lat"][0] <= lat <= COBERTURA["lat"][1] and COBERTURA["lon"][0] <= lon <= COBERTURA["lon"][1]


def ciudad_mas_cercana(lat, lon):
    nombre = min(CIUDADES, key=lambda c: haversine_km(lat, lon, CIUDADES[c]["lat"], CIUDADES[c]["lon"]))
    c = CIUDADES[nombre]
    return nombre, haversine_km(lat, lon, c["lat"], c["lon"])


def resolver_ubicacion(lat, lon):
    """Distancia de ruta a la bodega y condiciones (humedad, zona) de la ciudad más cercana."""
    ciudad, a_ciudad = ciudad_mas_cercana(lat, lon)
    km_bodega = max(1, round(haversine_km(lat, lon, BODEGA["lat"], BODEGA["lon"]) * FACTOR_RUTA))
    return {
        "ciudad_cercana": ciudad, "km_a_ciudad": round(a_ciudad), "km_bodega": km_bodega,
        "humedad": CIUDADES[ciudad]["humedad"], "zona": CIUDADES[ciudad]["zona"],
    }
