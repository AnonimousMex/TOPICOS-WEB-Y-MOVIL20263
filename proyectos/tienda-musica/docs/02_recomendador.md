# 02 · Recomendador de embalaje

Decide el nivel de embalaje y seguro de un envío: **básico** ($0), **reforzado** ($149) o **premium** ($299). El «recomendador» completo es **modelo + reglas + folio**; cuando se dice «el modelo» se habla solo del árbol.

## Piezas
| Pieza | Archivo | Qué es |
|---|---|---|
| Dataset | `backend/ml/generar_dataset.py` → `ml/datos/envios_instrumentos.csv` | 10,000 envíos **sintéticos** con 12 entradas y su nivel correcto |
| Entrenamiento | `backend/ml/entrenar_recomendador.py` | Lee el CSV, entrena y guarda el modelo |
| Modelo | `backend/ml/modelos/recomendador_arbol.joblib` (33 KB) | El árbol ya entrenado |
| Reglas | `backend/catalogo/reglas.py` | R1–R8, revisan lo que dijo el modelo |
| Servicio | `backend/catalogo/recomendador.py` | Carga el modelo y arma la respuesta |

## Las 12 entradas
`tipo`, `condicion`, `valor_mxn`, `peso_kg`, `dimension_max_cm`, `distancia_km`, `fragil`, `cantidad`, `humedad_destino`, `zona_riesgo`, `temporada`, `urgente`.
Para un producto del catálogo el cliente solo aporta cantidad y destino; el servidor completa el resto desde la base (`envios.py`) y convierte la ciudad en distancia, humedad y zona.

## Cómo se generó el dataset
Se inventan 10,000 envíos y se les asigna el nivel con una puntuación de riesgo (valor, fragilidad, peso, distancia, humedad, zona…) más ruido, con umbrales 2.2 y 3.7 (≈25 % básico, 40 % reforzado, 35 % premium). Además se cambia a propósito el 5 % de las etiquetas para no obtener una exactitud artificial de 100 %.

## Cómo se entrena
1. Separación estratificada: 8,000 filas de entrenamiento y 2,000 de prueba (`random_state=42`).
2. Preprocesamiento: imputador de mediana para números y one-hot para categorías.
3. Modelo principal: **árbol de decisión** (`max_depth=8`, `min_samples_leaf=5`), 160 hojas. Comparación: Random Forest (200 árboles, `max_depth=10`).
4. Se guarda un diccionario con el modelo, las columnas y las métricas en un `.joblib`.

El árbol divide los datos con preguntas de sí/no sobre las entradas (por ejemplo «¿el valor pasa de $9,720?») y termina en hojas que guardan la probabilidad de cada nivel.

## Qué guarda el `.joblib`
Las preguntas del árbol, la probabilidad de cada hoja y el preprocesamiento. **No guarda filas del dataset, búsquedas ni compras.** Por eso pesa 33 KB.

## Cómo se usa
1. El servidor carga el `.joblib` una vez (con `lru_cache`) y lo reutiliza.
2. En cada consulta recorre el árbol con las 12 entradas y obtiene nivel y probabilidad.
3. Las reglas revisan el resultado. **La probabilidad no cambia**; si una regla modifica el nivel, la respuesta lo indica (`corregido_por_reglas`) y explica el motivo.
4. El modelo **no aprende en producción**: no cambia con búsquedas ni compras. Para mejorarlo hay que juntar envíos reales, regenerar el CSV y volver a correr `entrenar_recomendador.py`.

## Reglas
| Regla | Condición | Efecto |
|---|---|---|
| R1 | valor ≥ $15,000 | al menos premium |
| R2 | cuerda frotada (violines y similares) | al menos reforzado |
| R3 | peso ≥ 20 kg o dimensión ≥ 120 cm | al menos reforzado |
| R4 | distancia ≥ 800 km y valor ≥ $5,000 | al menos reforzado |
| R5 | frágil y valor ≥ $8,000 | al menos reforzado |
| R6 | accesorio con valor < $800 | **máximo** reforzado (única regla que baja) |
| R7 | humedad alta y madera | al menos reforzado |
| R8 | zona de riesgo alta y valor ≥ $8,000 | al menos premium |

## Métricas (conjunto de prueba de 2,000 filas)
| Modelo | Exactitud | Tamaño |
|---|---|---|
| Árbol de decisión (principal) | 0.767 | 33 KB |
| Random Forest (comparación) | 0.805 | 13 MB |

Las reglas corrigieron 40 de los 2,000 casos (2 %): R8 29, R1 7, R3 2, R6 2. La exactitud contra la etiqueta no cambió. Su valor es de red de seguridad y explicabilidad, no de precisión. Reporte completo: [entrenamiento.md](../backend/ml/reportes/entrenamiento.md).

**Advertencia:** el dataset es sintético y la etiqueta sale de una fórmula con ruido, así que las métricas describen ese dataset y no envíos reales.

## Texto de la razón
La frase «considerando: larga distancia, pieza frágil» la arma la función `factores()` a partir de los datos del envío; no es la explicación interna del árbol.

## Respaldo
`RecomendadorConRespaldo` cae a `RecomendadorReglas` (sin modelo) si el `.joblib` falla. Con la variable de entorno `RECOMENDADOR=reglas` se fuerza ese modo.
