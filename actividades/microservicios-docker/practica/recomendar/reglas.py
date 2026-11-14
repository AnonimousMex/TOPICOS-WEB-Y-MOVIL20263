# Reglas de factibilidad del generador docente de Eduardo Alcaraz.

LIMITES = {
    "bicicleta": {"peso_kg": 8, "volumen_l": 40, "distancia_km": 7},
    "moto": {"peso_kg": 25, "volumen_l": 90, "distancia_km": 40},
    "camioneta": {"peso_kg": 1000, "volumen_l": 3000, "distancia_km": 1000},
    "dron": {"peso_kg": 2.5, "volumen_l": 12, "distancia_km": 15},
}

def es_posible(medio, p):
    limite = LIMITES[medio]
    if p["peso_kg"] > limite["peso_kg"] or p["volumen_l"] > limite["volumen_l"]:
        return False
    if p["distancia_km"] > limite["distancia_km"]:
        return False
    if p["refrigerado"] and medio != "camioneta":
        return False
    noche = p["hora_salida"] >= 21 or p["hora_salida"] < 6
    if medio == "dron":
        if p["clima"] != "despejado" or noche or p["zona_destino"] == "centro":
            return False
    if medio == "bicicleta" and p["zona_destino"] == "rural":
        return False
    return True
