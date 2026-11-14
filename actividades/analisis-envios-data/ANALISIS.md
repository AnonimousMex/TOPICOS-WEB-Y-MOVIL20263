# Análisis de los seis archivos de envíos

**Nombre:** Diego Rivera Cisneros — **Matrícula:** 22121364.

## Hipótesis y método

Se esperaba que el medio nuevo `eskuter` no pudiera predecirse y que balancear por sí solo no garantizara mayor exactitud. Se consultaron las notas compartidas como antecedente; los resultados siguientes se ejecutaron aquí. No son mediciones copiadas del compañero.

Se entrena el árbol en 8,000 filas de la base original, con las mismas 14 variables, profundidad 8 y mínimo 5 filas por hoja. Se evalúan los seis CSV docentes con ese único modelo. Se comparan las filas completas de atributos y etiqueta mediante hash para identificar las vistas durante entrenamiento; `id_envio` se excluye porque los generadores reutilizan identificadores. Este control no acredita independencia temporal ni ausencia de toda similitud estadística, pero sí detecta repetición exacta de contenido.

## Distribución por archivo

| archivo   | bicicleta   | camioneta   | dron   | eskuter   | moto   |
|:----------|:------------|:------------|:-------|:----------|:-------|
| envios1   | 25.00%      | 25.00%      | 25.00% | 0.00%     | 25.00% |
| envios2   | 26.16%      | 14.42%      | 8.55%  | 16.16%    | 34.71% |
| envios3   | 7.68%       | 15.79%      | 2.79%  | 0.00%     | 73.74% |
| envios4   | 18.75%      | 16.91%      | 7.09%  | 0.00%     | 57.25% |
| envios5   | 27.96%      | 16.78%      | 9.48%  | 0.00%     | 45.78% |
| envios6   | 4.24%       | 31.95%      | 0.73%  | 0.00%     | 63.08% |

## Resultados

| archivo   |   filas | exactitud_total   | baseline_mayoritaria   |   filas_vistas_entrenamiento | exactitud_no_vistas   |   clase_desconocida |
|:----------|--------:|:------------------|:-----------------------|-----------------------------:|:----------------------|--------------------:|
| envios1   |   10000 | 95.37%            | 25.00%                 |                            0 | 95.37%                |                   0 |
| envios2   |   10000 | 77.66%            | 34.71%                 |                            0 | 77.66%                |                1616 |
| envios3   |   10000 | 94.49%            | 73.74%                 |                            0 | 94.49%                |                   0 |
| envios4   |   10000 | 92.69%            | 57.25%                 |                            0 | 92.69%                |                   0 |
| envios5   |   10000 | 92.52%            | 45.78%                 |                         8000 | 92.10%                |                   0 |
| envios6   |   10000 | 96.15%            | 63.08%                 |                            0 | 96.15%                |                   0 |

**Hallazgo principal:** `envios5` contiene las 8,000 filas de entrenamiento y las 2,000 de prueba de la base. El 92.52% sobre el archivo completo mezcla evaluación aparente y evaluación independiente. La cifra que corresponde reportar para generalización en esa base es **92.10% sobre las 2,000 filas apartadas**, no 92.52%. Los demás cinco archivos no tienen coincidencias exactas con las filas de entrenamiento bajo este criterio.

## Interpretación por archivo

- **envios1:** las clases tienen 25% cada una, pero la exactitud de 95.37% no es la mayor. Balance no equivale a facilidad. La matriz muestra 453 drones interpretados como bicicleta.
- **envios2:** obtiene 77.66%; el modelo no tiene `eskuter` en sus clases. Falla sus 1,616 ejemplos: 1,405 como moto, 177 como bicicleta y 34 como dron. Si se mantiene un clasificador de cuatro clases, su exactitud no puede superar 83.84% en este archivo, incluso si acierta todos los medios conocidos.
- **envios3:** 73.74% de etiquetas son moto; 94.49% global supera el baseline, pero no elimina problemas de minorías. Hay 204 camionetas predichas como moto.
- **envios4:** 92.69%; errores de camioneta y bicicleta hacia moto muestran el efecto de la clase común. Hay que distinguir factibilidad de coincidencia con la etiqueta.
- **envios5:** su distribución replica la base y revela por qué se debe conservar la partición. La evaluación válida es 92.10%; entrenar con todo y luego evaluar las mismas filas agravaría la fuga.
- **envios6:** 96.15% global, pero solo 73 drones reales. Acertar 61 da recall de 83.56%; 43 motos adicionales clasificadas como dron contribuyen a reducir su precisión a 58.10%. La cifra incluye todos los falsos positivos, no solo ese par de la matriz.

## Decisión

Un modelo no puede crear una clase de salida que no tiene: para incorporar `eskuter` se necesitan contrato, reglas y entrenamiento nuevos. Un buen promedio en el archivo más desbalanceado no demuestra que reconozca bien todos los medios. Publicaría exactitud y métricas por clase junto al soporte, el baseline y el conteo de filas previamente vistas.

Estos resultados miden acuerdo con etiquetas sintéticas. La evaluación de costo y reglas en la actividad 6 ayuda a no confundir desacuerdo con peor decisión.

## Reproducción y evidencias

El código de evaluación está en [analizar.py](../analisis-dataset/analizar.py). Los seis CSV están en `../analisis-dataset/datos/`; matrices y reportes, en `resultados/`.

Fuentes: [datasets del profesor](https://github.com/ealcaraz85/topicoswebmobil/tree/639e2d001ebace36a55897bac9b768ea0e25a232/proyectos/dataset-medios) y [análisis compartido consultado](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/actividades/analisis-envios-data/analisis_envios-data.md).
