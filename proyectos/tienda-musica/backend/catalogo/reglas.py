"""Reglas de negocio que se aplican DESPUÉS del modelo (separadas de él, como pide el curso).

El modelo estima; las reglas garantizan mínimos de seguridad que no se negocian
(por ejemplo, un instrumento caro nunca viaja sin seguro total).
"""

NIVELES = ["basico", "reforzado", "premium"]
COSTO_MXN = {"basico": 0, "reforzado": 149, "premium": 299}  # cargo por embalaje y seguro
MADERA = {"guitarra", "cuerda_frotada", "percusion"}

DESCRIPCION = {
    "basico": "Caja con relleno, sin seguro adicional.",
    "reforzado": "Caja doble con esquineros y seguro parcial.",
    "premium": "Estuche rígido, caja doble y seguro total contra daño y extravío.",
}


def _indice(nivel):
    return NIVELES.index(nivel)


def aplicar_reglas(nivel_modelo, e):
    """Devuelve (nivel_final, [reglas aplicadas]).

    `e` es el diccionario de entradas: tipo, valor_mxn, peso_kg, dimension_max_cm, distancia_km,
    fragil, y opcionalmente humedad_destino y zona_riesgo.
    """
    nivel = nivel_modelo
    aplicadas = []

    def piso(minimo, codigo, texto):
        nonlocal nivel
        if _indice(nivel) < _indice(minimo):
            aplicadas.append({"regla": codigo, "efecto": f"sube a {minimo}", "motivo": texto})
            nivel = minimo

    def techo(maximo, codigo, texto):
        nonlocal nivel
        if _indice(nivel) > _indice(maximo):
            aplicadas.append({"regla": codigo, "efecto": f"baja a {maximo}", "motivo": texto})
            nivel = maximo

    if e["valor_mxn"] >= 15000:
        piso("premium", "R1_VALOR_ALTO", "Un instrumento de $15,000 o más siempre lleva seguro total.")
    if e["tipo"] == "cuerda_frotada":
        piso("reforzado", "R2_CUERDA_FROTADA", "Violines y similares se desajustan con golpes leves.")
    if e["peso_kg"] >= 20 or e["dimension_max_cm"] >= 120:
        piso("reforzado", "R3_VOLUMEN", "Piezas grandes o pesadas necesitan caja doble.")
    if e["distancia_km"] >= 800 and e["valor_mxn"] >= 5000:
        piso("reforzado", "R4_LARGA_DISTANCIA", "Más de 800 km con valor mayor a $5,000 exige seguro parcial.")
    if e["fragil"] and e["valor_mxn"] >= 8000:
        piso("reforzado", "R5_FRAGIL_CARO", "Pieza frágil de $8,000 o más.")
    if e.get("humedad_destino") == "alta" and e["tipo"] in MADERA:
        piso("reforzado", "R7_HUMEDAD", "Destino de humedad alta: la madera se hincha y se agrieta sin protección.")
    if e.get("zona_riesgo") == "alta" and e["valor_mxn"] >= 8000:
        piso("premium", "R8_ZONA_DE_RIESGO", "Entrega en zona de riesgo alto con valor de $8,000 o más: seguro total.")
    if e["tipo"] == "accesorio" and e["valor_mxn"] < 800:
        techo("reforzado", "R6_ACCESORIO_BARATO", "Un accesorio menor a $800 no justifica estuche rígido ni seguro total.")

    return nivel, aplicadas
