# Hipótesis previas a esta ejecución

**Actividad de:** Diego Rivera Cisneros — 22121364.

Estas hipótesis se registraron antes de ejecutar el script de esta entrega; no son evidencia de asistencia a clase ni de una predicción personal previa del alumno. El análisis histórico de las actividades 1–5 ya estaba en el repositorio y se usa como antecedente.

1. Con lluvia dominará moto; en centro, bicicleta. No habrá etiquetas imposibles y la bici no superará 7 km. No podrán inferirse los límites superiores de camioneta porque el generador no los alcanza.
2. No habrá dron a las 3:00; la noche tendrá pocos ejemplos. Una variable nocturna explícita reducirá recomendaciones inválidas, sin sustituir las reglas.
3. Moto y bicicleta se confundirán más que bicicleta y camioneta. Los drones nocturnos propuestos por el árbol serán corregidos por las reglas.
4. Distancia, volumen, clima y refrigeración explicarán buena parte de la clasificación. Una variable correlacionada puede tener importancia cero sin ser irrelevante para el negocio.
5. Balancear elevará recall de dron, con riesgo de perder precisión y exactitud. No se tocará la prueba para comparar modelos, salvo la demostración explícita de una evaluación sesgada.
6. La decisión sin ruido no coincidirá con todas las etiquetas. El árbol podrá reducir el costo de algunos «errores» respecto del operador, pero no esperamos que supere al óptimo de la fórmula.
7. Reducir peso sin cambiar factibilidad no debe cambiar el óptimo; 10:00 y 16:00 serán equivalentes con tráfico fijo. Un árbol sin restricciones tendrá más incoherencias, pero la cifra debe medirse. Valor alto puede revelar una carencia incluso si el modelo parece estable.
8. Ampliar capacidad del dron dañará más la exactitud que cambiar el clima. La confianza no necesariamente caerá. Los datos nuevos corregidos deberían ser más útiles que conservar muchas etiquetas del régimen anterior.

## Seis archivos adicionales

El modelo solo conoce cuatro clases, por lo que fallará en todos los `eskuter`. Un dataset balanceado no garantiza mayor exactitud. En archivos con pocos drones, unos cuantos falsos positivos pueden reducir mucho su precisión.
