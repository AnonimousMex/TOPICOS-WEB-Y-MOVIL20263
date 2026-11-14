# Análisis del dataset de medios — Actividades 1 a 8

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364.

## Alcance, método y reproducción

Este trabajo ejecuta análisis sobre datos sintéticos del profesor; no toca el proyecto personal ni el del equipo. Se analizan ocho actividades: distribución, horario, errores, importancia de variables, balanceo, costo, coherencia y cambio de condiciones.

Se regenera la base con 10,000 filas y semilla 42 utilizando el generador docente sin modificar. Se separan 8,000/2,000 filas con estratificación y semilla 42, se ajusta el preprocesamiento únicamente en entrenamiento y se entrena un árbol de profundidad 8 con mínimo 5 filas por hoja. Se usa `predict_proba` y el primer medio posible del ranking para la recomendación con reglas. El script comprueba que entrenamiento y prueba no comparten índices.



La ejecución produce CSV, un modelo entrenado aquí, un resumen y hashes de entradas. El `.joblib` guardado fue generado por este script; no se cargaron modelos serializados de terceros. Las versiones efectivas constan en [ejecucion.json](resultados/ejecucion.json). 

## 1. El retrato del dataset

**Predicción:** moto con lluvia, bicicleta en centro, cero etiquetas imposibles; el límite operativo de camioneta no será observable.

**Resultado:** hay 4,578 motos, 2,796 bicicletas, 1,678 camionetas y 948 drones. Con lluvia la moto representa 74.83%; en centro, la bicicleta 58.45%. Ninguna etiqueta rompe factibilidad.

1. **Dónde no hay dron:** lluvia y viento fuerte, por la regla de clima; centro, por restricción de zona; rural, porque los envíos observados superan su alcance de 15 km, no por una prohibición explícita de dron rural. La ausencia observada y la regla son afirmaciones distintas.
2. **Bici en periferia:** solo 2.25% de sus envíos están a 7 km o menos. La distancia explica por qué no basta mirar la etiqueta de zona: se observan 18 bicicletas entre 2,046 envíos a periferia.
3. **Máximos:** bicicleta 7.99 kg / 39.70 L / 7.00 km; moto 24.93 kg / 89.99 L / 39.90 km; dron 2.50 kg / 11.98 L / 14.99 km. Se acercan a los límites configurados. La camioneta llega a 80 kg / 400.57 L / 59.12 km: son máximos observados, muy inferiores a sus límites de 1,000 kg / 3,000 L / 1,000 km. El redondeo de dimensiones explica que el volumen observado supere ligeramente los 400 L objetivo del generador.
4. **Camionetas de menos de 2 km:** 107. Hay 61 que exceden la capacidad de moto y 36 refrigeradas, con 2 casos que cumplen ambas condiciones: la unión es 95, no 97. Quedan 12 sin esas razones físicas; pueden explicarse por puntaje y ruido, pero no se puede atribuir cada etiqueta al ruido sin su traza de generación. El texto anterior contaba 59 como categoría exclusiva: 61 − 2 = 59.

**Comparación y decisión:** se cumplen las hipótesis. El CSV permite aproximar límites vistos; no demuestra límites nunca alcanzados, causales ni excepciones que no aparecieron. Las reglas obligatorias deben estar explícitas en el servidor, incluso cuando el modelo parece haberlas aprendido.

**Evidencia:** [clima](resultados/01_clima.csv), [zonas](resultados/01_zona_destino.csv), [límites](resultados/01_limites.csv) y [metadatos con conteos](resultados/ejecucion.json).

## 2. La hora y el dron

**Predicción:** no habrá dron a las 3:00; una columna nocturna ayudará.

**Resultado:** 1,053 envíos nocturnos y 8,947 diurnos. Cero drones entre 0–5 y 21–23; el rango observado coincide con la regla de 6:00 a 20:59. La bicicleta pasa de 30.1% a las 20:00 a 6.3% a las 21:00: la penalización nocturna de 30 puntos cambia su competencia con moto. No es una prohibición física de bicicleta nocturna.

Un árbol necesita al menos dos cortes para representar `hora < 6 or hora >= 21`, pues la noche ocupa ambos extremos de la variable lineal. Se añadió `es_de_noche` con esa expresión, calculada sin mirar etiquetas.

|             |   filas | exactitud   | exactitud_reglas   | precision_dron   | recall_dron   |   predice_dron |   imposibles | confianza_media   |
|:------------|--------:|:------------|:-------------------|:-----------------|:--------------|---------------:|-------------:|:------------------|
| base        |    2000 | 92.10%      | 93.65%             | 83.90%           | 90.53%        |            205 |           31 | 92.54%            |
| es_de_noche |    2000 | 92.95%      | 93.65%             | 91.01%           | 90.53%        |            189 |           14 | 92.95%            |

**Comparación y decisión:** mejoró la exactitud cruda de 92.10% a 92.95% y bajaron las sugerencias imposibles de 31 a 14. Tras aplicar reglas, ambos llegan a 93.65%: la columna ayuda a representar la noche, pero no reemplaza factibilidad. El poco soporte nocturno obliga a revisar errores por segmento, no solo la media.

**Evidencia:** [distribución por hora](resultados/02_horas.csv) y [comparación completa](resultados/02_comparacion.csv).

## 3. Anatomía de los errores

**Predicción:** habrá más confusiones entre moto y bicicleta que entre bici y camioneta.

**Resultado:** 158 errores crudos; los tres grupos mayores son moto → bicicleta (46), camioneta → moto (32) y moto → dron (29). Ninguna bicicleta real fue predicha como camioneta.

De los 29 casos moto → dron, 26 son nocturnos y las reglas los corrigen. Los otros tres ocurren de día y el dron es posible, por lo que las reglas de seguridad no detectan la diferencia con la etiqueta. Los 46 moto → bici tienen una mediana de distancia de 3.88 km; solo tres superan 6.5 km. Por tanto, no basta mover el umbral de 7 km. En ellos hay mayor presencia de prioridad `mismo_dia` y clima no despejado que entre las bicicletas acertadas.

Si se usa otra partición para evaluar un modelo ya entrenado, pueden entrar a prueba filas que aquel modelo sí vio. Debe reconstruirse la partición original o entrenarse un modelo nuevo con un conjunto externo intacto. Cambiar la semilla sin reentrenar no crea una evaluación independiente.

**Comparación y decisión:** se confirma la confusión entre medios cercanos. Priorizaría errores operativamente imposibles con reglas y después el costo de las decisiones viables. La actividad 6 muestra por qué no trataría automáticamente cada desacuerdo con la etiqueta como un error del modelo.

**Evidencia:** [matriz](resultados/03_matriz.csv), [confusiones](resultados/03_confusiones.csv) y [casos detallados](resultados/03_errores_detalle.csv).

## 4. Qué columnas usa el árbol

**Predicción:** distancia, volumen, clima y refrigeración estarán entre las más importantes; correlación puede ocultar una variable.

|                     | importancia   |
|:--------------------|:--------------|
| distancia_km        | 32.20%        |
| volumen_l           | 19.29%        |
| clima               | 14.38%        |
| refrigerado         | 13.13%        |
| peso_kg             | 12.63%        |
| hora_salida         | 5.87%         |
| fragil              | 1.99%         |
| prioridad           | 0.31%         |
| valor_declarado_mxn | 0.07%         |
| ancho_cm            | 0.07%         |
| largo_cm            | 0.03%         |
| alto_cm             | 0.03%         |
| trafico             | 0.02%         |
| zona_destino        | 0.00%         |

Las primeras divisiones del [árbol exportado](resultados/04_arbol.txt) incluyen distancia, volumen, lluvia y refrigeración. Sin distancia, la exactitud cae de 92.10% a 79.30% (−12.80 puntos); sin clima, a 84.45%; sin refrigeración, a 87.85%. Quitar zona, valor declarado o tráfico no altera la exactitud en esta partición. Quitar prioridad la sube apenas 0.05 puntos; no basta para afirmar una mejora general.

Importancia cero de zona no implica que pueda eliminarse: las reglas prohíben el dron en centro y usan la zona rural para bicicleta. Distancia y otras variables correlacionadas pueden explicar parte de lo que el árbol aprende. Las dimensiones aportan información similar al volumen. Importancia interna y efecto de retirar una columna miden cosas distintas.

**Comparación y decisión:** se cumple el grupo principal previsto. Mantendría un dato si lo requieren reglas, facturación o seguimiento, aunque el modelo actual no lo use. No pediría información al comprador sin propósito definido solo porque exista en el dataset.

**Evidencia:** [ablación de las 14 columnas](resultados/04_ablacion.csv).

## 5. Balancear el dron

### A. Antes de experimentar

Un clasificador hipotético que nunca acierte un dron pero **acierte todos los demás envíos** alcanzaría 90.52%. La condición es esencial: simplemente «no predecir dron» no garantiza eso en cuatro clases. Siempre responder moto da 45.78%. Para evaluar convienen precisión y recall por medio, matriz, errores imposibles y costo.

El soporte bajo del dron refleja restricciones reales del escenario. Se balancea solo entrenamiento, después de separar la prueba. Balancear antes puede filtrar duplicados; balancear prueba cambia la prevalencia y deja de representar la operación.

### B. Experimentos

Se probaron tres alternativas: reducir todas las clases a 758 casos, repetir drones hasta la cantidad de motos y usar `class_weight='balanced'`. Todos conservan la misma prueba de 2,000 filas, con 190 drones.

| estrategia        |   entrenamiento |   filas | exactitud   | exactitud_reglas   | precision_dron   | recall_dron   |   predice_dron |   imposibles | confianza_media   |
|:------------------|----------------:|--------:|:------------|:-------------------|:-----------------|:--------------|---------------:|-------------:|:------------------|
| sin_balancear     |            8000 |    2000 | 92.10%      | 93.65%             | 83.90%           | 90.53%        |            205 |           31 | 92.54%            |
| submuestreo       |            3032 |    2000 | 89.75%      | 90.90%             | 88.94%           | 93.16%        |            199 |           29 | 91.41%            |
| repetir_drones    |           10905 |    2000 | 90.00%      | 92.15%             | 72.80%           | 100.00%       |            261 |           54 | 93.37%            |
| pesos_balanceados |            8000 |    2000 | 90.25%      | 91.55%             | 76.61%           | 100.00%       |            248 |           35 | 92.02%            |

Los resultados de remuestreo dependen de cómo se seleccionan las filas y su orden; por eso las cifras de las estrategias no tienen por qué coincidir con el informe histórico sin sus scripts. Los parámetros y resultados de esta ejecución están registrados en los archivos adjuntos.

**Trampa deliberada:** se balanceó únicamente la evaluación por remuestreo, sin mejorar el modelo. La precisión de dron pasa de 83.90% a 95.30%, pero la prueba dejó de reflejar el tráfico real. No hubo mejora del estimador ni se presenta esta cifra como válida para producción. [Resultado sesgado](resultados/05_prueba_sesgada.csv).

### C. Interpretación

Repetir drones y ponderar clases elevan su recall a 100%, a cambio de más falsos positivos y menor exactitud. El submuestreo es una excepción a «la precisión siempre baja»: en esta ejecución sube a 88.94%, mientras recall sube a 93.16%, pero pierde exactitud global y 4,968 filas de entrenamiento (62.1%). Es necesario medir, no forzar el resultado esperado.

Duplicación y pesos alteran de forma parecida el costo del error, pero no son idénticos: el muestreo cambia composición, frecuencias y restricciones efectivas de las hojas. Las probabilidades de hojas tampoco están calibradas automáticamente; tras alterar prevalencias, no se interpretan como garantía de acierto de cada sugerencia.

### D. Decisión

Mantendría el modelo sin balancear como referencia: obtiene 93.65% con reglas frente a 90.90–92.15% de las alternativas. Verificaría costo operativo antes de aprobar otro. El número de drones comprado no cambia automáticamente la distribución de etiquetas: hacen falta datos del régimen nuevo. Las reglas corrigen inviabilidad, pero no toda recomendación viable y costosa.

## 6. Quién se equivoca: modelo o etiquetas

**Predicción:** habrá etiquetas con ruido y desacuerdos que favorezcan al modelo.

`SinRuido.gauss` devuelve 1.0; así se evalúa la fórmula docente sin perturbación. Para cada envío se toma el menor puntaje entre medios factibles. El modelo se evalúa tanto crudo como con reglas; no se cobra costo a una sugerencia imposible.

El óptimo coincide con **93.65%** de las etiquetas de prueba. Es una referencia de acuerdo con decisiones sin ruido, no un límite matemático universal a la exactitud: algún ruido podría tener estructura predecible. El modelo crudo queda 1.55 puntos por debajo; con reglas iguala ese acuerdo, aunque no coincide con el óptimo en todas las filas. El acuerdo modelo con reglas–óptimo es **98.10%**.

De 127 desacuerdos entre modelo con reglas y etiqueta, **107 eligen el óptimo** de la fórmula. Por tanto, buena parte de los «errores» de la actividad 3 son discrepancias con operadores simulados y no peores decisiones. El archivo de casos permite revisar cada par sin generalizar a todos los errores moto–bici.

|                  |   costo_total |   sobrecosto_porcentaje |
|:-----------------|--------------:|------------------------:|
| optimo           |        242270 |                0        |
| etiquetas        |        247789 |                2.27788  |
| modelo_reglas    |        242689 |                0.172997 |
| entrenado_optimo |        242632 |                0.149417 |

El puntaje suma dinero, tiempo ponderado y penalizaciones: sus totales son **puntos de esa función**, no pesos mexicanos reales. El modelo reduce el sobrecosto de las etiquetas (2.2779%) a 0.1730%. Limitar hojas amortigua decisiones individuales ruidosas. El árbol entrenado con etiquetas óptimas baja a 0.1494%; la mejora marginal de costo es aproximadamente 0.0236 puntos respecto del óptimo, no una justificación automática de pagar limpieza manual.

**Comparación y decisión:** se confirma el ruido y el costo mejora aunque se discrepe de etiquetas. Si la fórmula es conocida y barata, usaría directamente optimización por reglas para este problema de cuatro opciones. El modelo tiene sentido si el costo real depende de decisiones humanas no formalizadas, por ejemplo daño y demora observados. Sin oráculo, revisaría muestras con expertos, resultados de entrega, costo y cambios de operador, sin asumir que la etiqueta histórica es verdad absoluta.

**Evidencia:** [acuerdos y metadatos](resultados/ejecucion.json), [casos](resultados/06_casos.csv) y [costos](resultados/06_costos.csv).

## 7. Coherencia y sensibilidad

**Predicción:** el árbol profundo romperá más propiedades. No se supone que toda reducción de distancia conserve el vehículo.

Las cuatro propiedades se deducen de la fórmula y también se comprueban contra el óptimo:

1. **Peso a la mitad, misma factibilidad:** el puntaje no usa peso, solo lo usan límites; si no cambia el conjunto de medios posibles, la elección óptima debe permanecer. Se comparan 1,936 de 2,000 casos que cumplen esa precondición.
2. **Hora 10 → 16 con tráfico fijo:** ambas son diurnas y puntaje no usa otra dependencia de la hora, así que no debe cambiar el medio.
3. **Fragilidad 0 → 1:** añade cero a camioneta y penalizaciones no negativas a los demás; si ya ganaba camioneta, no puede perder por ese único cambio.
4. **Tráfico bajo → alto:** el dron no cambia de velocidad y los terrestres empeoran o quedan iguales; si ganaba dron y conserva factibilidad, no debe perder.

Se cuentan violaciones de recomendaciones **con reglas**. La columna de exactitud siguiente se mide sobre predicción cruda para comparar con las otras actividades.

|               | exactitud   |   peso_sin_cambio_factibilidad |   hora_10_a_16 |   fragil_sale_camioneta |   trafico_sale_dron |   casos_peso_comparables |
|:--------------|:------------|-------------------------------:|---------------:|------------------------:|--------------------:|-------------------------:|
| profundidad_8 | 92.10%      |                              2 |              0 |                       0 |                   0 |                     1936 |
| sin_limite    | 89.30%      |                             94 |             36 |                       2 |                   3 |                     1936 |

**La propiedad de distancia propuesta es falsa.** En un paquete de 24.45 kg, 48.11 L, frágil, no refrigerado, con lluvia, tráfico bajo y prioridad normal, el óptimo a 1.95 km es moto: 110.4798 puntos frente a 112.3200 de camioneta. A 0.975 km, moto cuesta 105.9899 y camioneta 102.9600: ahora gana camioneta. La penalización de fragilidad y lluvia cambia la intersección de costos; no es una incoherencia del oráculo. Se encontró un caso de ese tipo entre las 2,000 transformaciones.

**Valor declarado:** al sustituir 1,000 por 30,000 en los mismos envíos, el modelo cambia **0** decisiones; el óptimo cambia **352**. Solo hay 43 filas del dataset por encima de 20,000. La estabilidad puede esconder insensibilidad a un factor importante. Una prueba que solo prohíba movimientos erróneos no detecta falta de reacción; hace falta una prueba de sensibilidad comparada con el resultado esperado en casos pertinentes.

**Comparación y decisión:** el árbol profundo baja exactitud a 89.30% y suma muchas más violaciones. La propiedad del peso pasa de 2 a 94; la de hora, de 0 a 36. Memorizar ruido crea particiones espurias. Para aceptar un modelo exigiría cero sugerencias finales inviables, cero cambios en casos diurnos equivalentes y métricas por propiedad no peores que el modelo base. Las tolerancias sobre aprendizaje se fijan con un conjunto validado, no con porcentajes arbitrarios. Preferiría 92% y dos incoherencias a 93% y cincuenta si el costo es comparable; primero miraría gravedad. Las reglas detectan lo imposible, pero no un vehículo viable innecesariamente caro ni la falta de sensibilidad al valor.

**Evidencia:** [propiedades](resultados/07_propiedades.csv) y [contraejemplo y sensibilidad](resultados/RESULTADOS.md).

## 8. El mundo cambia

**Predicción:** ampliar la capacidad del dron perjudicará más la exactitud que el cambio climático; la confianza no necesariamente avisará.

Se generaron 5,000 filas por escenario con semilla 99: original, lluvias (30% despejado, 55% lluvia, 15% viento) y dron de 5 kg / 25 L / 25 km. El conjunto de adaptación tiene 1,000 filas con semilla 123. Ninguno se usa como prueba y entrenamiento a la vez. La semilla igual controla la generación, pero cambiar medios posibles cambia el consumo posterior del RNG: no se presume que cada fila sea una pareja idéntica entre escenarios.

| escenario            | exactitud_cruda   | exactitud_reglas   | confianza_media   | corregidas   |   imposibles_finales | recomienda_bicicleta   | recomienda_moto   | recomienda_camioneta   | recomienda_dron   |
|:---------------------|:------------------|:-------------------|:------------------|:-------------|---------------------:|:-----------------------|:------------------|:-----------------------|:------------------|
| referencia           | 92.58%            | 93.74%             | 92.54%            | 1.16%        |                    0 | 31.64%                 | 44.42%            | 15.42%                 | 8.52%             |
| lluvias              | 92.26%            | 93.08%             | 92.73%            | 0.84%        |                    0 | 19.44%                 | 61.40%            | 15.48%                 | 3.68%             |
| drones               | 83.12%            | 84.02%             | 92.59%            | 0.94%        |                    0 | 30.70%                 | 45.96%            | 14.34%                 | 9.00%             |
| drones_reglas_nuevas | 83.12%            | 84.02%             | 92.59%            | 0.94%        |                    0 | 30.70%                 | 45.96%            | 14.34%                 | 9.00%             |

Con reglas la referencia da 93.74%; lluvias 93.08%; dron ampliado 84.02%. La confianza media apenas pasa de 92.54% a 92.59% en el cambio de dron. El clima es una distribución de entradas ya representadas y el modelo sigue reconociendo sus efectos; la capacidad nueva cambia qué decisión conviene para atributos que antes llevaban otra etiqueta.

**Señales sin etiqueta:** para lluvia, observar proporciones de clima y cambios del tráfico de recomendaciones permite detectar deriva de entradas. Para la nueva capacidad puede no existir señal en esas entradas: el paquete no lleva un atributo de «versión de flota». Hay que registrar cambios operativos y decisiones del operador; la confianza alta no es un detector suficiente. Una baja tasa de corrección por reglas tampoco prueba vigencia del modelo.

**Actualizar reglas sin reentrenar:** deja la exactitud en 84.02%. Ampliar factibilidad permite nuevas opciones, pero no enseña al árbol a preferirlas; no aparece un cambio útil de ranking en este conjunto. El resultado se midió, no se asumió.

|    | estrategia                      |   nuevos |   total | exactitud_reglas   | acuerdo_optimo_nuevo   |
|---:|:--------------------------------|---------:|--------:|:-------------------|:-----------------------|
|  0 | solo_nuevos                     |      200 |     200 | 79.70%             | 82.84%                 |
|  1 | viejos_mas_nuevos               |      200 |   10200 | 84.12%             | 88.18%                 |
|  2 | viejos_reetiquetados_mas_nuevos |      200 |   10200 | 93.02%             | 97.58%                 |
|  3 | solo_nuevos                     |      500 |     500 | 86.12%             | 89.60%                 |
|  4 | viejos_mas_nuevos               |      500 |   10500 | 84.08%             | 88.06%                 |
|  5 | viejos_reetiquetados_mas_nuevos |      500 |   10500 | 93.10%             | 97.62%                 |
|  6 | solo_nuevos                     |     1000 |    1000 | 90.10%             | 93.70%                 |
|  7 | viejos_mas_nuevos               |     1000 |   11000 | 84.10%             | 88.20%                 |
|  8 | viejos_reetiquetados_mas_nuevos |     1000 |   11000 | 92.98%             | 97.50%                 |

**Tres enfoques:** solo datos nuevos (200/500/1,000), 10,000 viejos más esos nuevos y una propuesta de reetiquetar datos viejos con el óptimo bajo los límites nuevos. Solo 1,000 nuevos logran 90.10%; mezclar 10,000 viejos con 1,000 nuevos da 84.10%. Las etiquetas antiguas dominan aunque sus recomendaciones ya no sean óptimas. La tercera estrategia llega a 92.98% con 1,000 nuevos; es una ventaja propia de esta simulación, donde conocemos la fórmula. En un negocio real requeriría decisiones recientes o revisión de expertos; no se puede inventar un óptimo desconocido. No se ajustaron hiperparámetros con la prueba de 5,000: se usa solo para comparar las alternativas solicitadas.

**Comparación y decisión:** se confirma que cambió la decisión objetivo sin caída clara de confianza. Guardaría atributos de entrada, medio sugerido y elegido, versión de modelo y reglas, capacidad vigente, motivo del cambio del operador y resultado de la entrega, minimizando datos personales. Un evento del dominio puede registrar la discrepancia después del commit, fuera de la vista.

El orden propuesto es: aprobar capacidades, actualizar reglas y pruebas de seguridad, recoger/reetiquetar datos con la nueva versión, entrenar fuera del servidor, validar en datos independientes, publicar artefacto versionado y monitorear con posibilidad de volver atrás. Una métrica de costo o desacuerdo validada dispara la revisión; el equipo responsable decide la publicación. No lo decide el propio modelo por su confianza.

## Fuentes y límites

- [Enunciados y etapas del profesor](https://ealcaraz85.github.io/topicoswebmobil/#orgeebe190).
- [Generador docente, versión consultada](https://github.com/ealcaraz85/topicoswebmobil/blob/639e2d001ebace36a55897bac9b768ea0e25a232/proyectos/dataset-medios/generar_dataset.py).
- [Notas compartidas consultadas](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/tree/6397468bd6c15e68a7a4fdee786917b470c825e7/actividades/analisis-dataset).

Los datos son sintéticos y no prueban desempeño real de una empresa. Las versiones y parámetros hacen reproducible esta entrega; no garantizan que un entorno distinto produzca exactamente los mismos cortes de árbol.
