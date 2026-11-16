"""Strategy: cada nivel de embalaje sabe armar su propio plan de preparación (como `medios.py` del curso).

`crear_nivel(nombre)` es la fábrica; agregar un nivel nuevo no obliga a tocar vistas ni cliente.
"""
from abc import ABC, abstractmethod

from .reglas import COSTO_MXN, DESCRIPCION, MADERA


class Nivel(ABC):
    nombre = ""
    horas_base = 0.5

    @abstractmethod
    def materiales(self, e):
        """Lista base de materiales."""

    cobertura = ""

    def plan(self, e):
        materiales = list(self.materiales(e))
        horas = self.horas_base
        if e.get("humedad_destino") == "alta" and e["tipo"] in MADERA:
            materiales.append("Bolsa antihumedad con sílice")
            horas += 0.25
        if e.get("fragil"):
            materiales.append("Etiquetas «Frágil» en todas las caras")
        if e.get("cantidad", 1) > 1:
            materiales.append(f"Separadores individuales para {e['cantidad']} piezas")
            horas += 0.25 * (e["cantidad"] - 1)
        if e.get("urgente"):
            horas = max(0.5, horas - 0.25)
        return {
            "nivel": self.nombre, "descripcion": DESCRIPCION[self.nombre], "materiales": materiales,
            "cobertura_seguro": self.cobertura, "tiempo_preparacion_h": round(horas, 2), "costo_mxn": COSTO_MXN[self.nombre],
        }


class Basico(Nivel):
    nombre, horas_base, cobertura = "basico", 0.25, "Sin seguro adicional (cobertura mínima del transportista)"

    def materiales(self, e):
        return ["Caja de cartón", "Relleno de papel kraft"]


class Reforzado(Nivel):
    nombre, horas_base, cobertura = "reforzado", 0.5, "Seguro parcial: hasta 50 % del valor declarado"

    def materiales(self, e):
        return ["Caja de doble pared", "Esquineros de espuma", "Plástico burbuja", "Cinta reforzada"]


class Premium(Nivel):
    nombre, horas_base, cobertura = "premium", 1.0, "Seguro total: 100 % del valor declarado contra daño y extravío"

    def materiales(self, e):
        return ["Estuche rígido con espuma a medida", "Caja exterior de doble pared", "Esquineros rígidos", "Sello de seguridad numerado"]


_NIVELES = {c.nombre: c for c in (Basico, Reforzado, Premium)}


def crear_nivel(nombre):
    return _NIVELES[nombre]()
