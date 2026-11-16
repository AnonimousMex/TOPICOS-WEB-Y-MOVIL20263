# Reporte de entrenamiento del recomendador

scikit-learn 1.9.1 · 8000 filas de entrenamiento, 2000 de prueba (20 %, estratificado, random_state=42).
Datos sintéticos: las métricas describen el dataset, no envíos reales.

## Árbol de decisión (principal)

Accuracy en prueba: **0.767**

```
              precision    recall  f1-score   support

      basico       0.86      0.71      0.78       389
     premium       0.84      0.80      0.82       870
   reforzado       0.66      0.75      0.71       741

    accuracy                           0.77      2000
   macro avg       0.79      0.76      0.77      2000
weighted avg       0.78      0.77      0.77      2000

```

Matriz de confusión (filas = real, columnas = predicho; orden: basico, premium, reforzado):

```
[[278   0 111]
 [  0 698 172]
 [ 45 137 559]]
```

## Random Forest (comparación)

Accuracy en prueba: **0.805**

```
              precision    recall  f1-score   support

      basico       0.85      0.74      0.79       389
     premium       0.87      0.85      0.86       870
   reforzado       0.72      0.78      0.75       741

    accuracy                           0.81      2000
   macro avg       0.81      0.79      0.80      2000
weighted avg       0.81      0.81      0.81      2000

```

Matriz de confusión (filas = real, columnas = predicho; orden: basico, premium, reforzado):

```
[[286   0 103]
 [  0 743 127]
 [ 50 110 581]]
```

## Profundidad y sobreajuste (árbol)

| max_depth | accuracy entrenamiento | accuracy prueba |
|---|---|---|
| 2 | 0.724 | 0.702 |
| 4 | 0.768 | 0.743 |
| 6 | 0.795 | 0.758 |
| 8 | 0.824 | 0.767 |
| 12 | 0.871 | 0.769 |
| sin límite | 0.890 | 0.756 |

Cuanto más profundo, mejor en entrenamiento y peor (o igual) en prueba: el árbol memoriza el ruido.

## Reglas aprendidas (primeros 3 niveles)

```
|--- cat__tipo_accesorio <= 0.50
|   |--- num__valor_mxn <= 9720.67
|   |   |--- num__distancia_km <= 898.50
|   |   |   |--- cat__tipo_cuerda_frotada <= 0.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- cat__tipo_cuerda_frotada >  0.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |--- num__distancia_km >  898.50
|   |   |   |--- num__distancia_km <= 1387.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__distancia_km >  1387.50
|   |   |   |   |--- truncated branch of depth 5
|   |--- num__valor_mxn >  9720.67
|   |   |--- num__valor_mxn <= 15797.95
|   |   |   |--- num__distancia_km <= 461.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__distancia_km >  461.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |--- num__valor_mxn >  15797.95
|   |   |   |--- num__valor_mxn <= 19058.81
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__valor_mxn >  19058.81
|   |   |   |   |--- truncated branch of depth 5
|--- cat__tipo_accesorio >  0.50
|   |--- num__distancia_km <= 953.50
|   |   |--- num__fragil <= 0.50
|   |   |   |--- num__peso_kg <= 1.10
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__peso_kg >  1.10
|   |   |   |   |--- truncated branch of depth 5
|   |   |--- num__fragil >  0.50
|   |   |   |--- cat__zona_riesgo_alta <= 0.50
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- cat__zona_riesgo_alta >  0.50
|   |   |   |   |--- truncated branch of depth 5
|   |--- num__distancia_km >  953.50
|   |   |--- num__fragil <= 0.50
|   |   |   |--- num__distancia_km <= 1540.00
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__distancia_km >  1540.00
|   |   |   |   |--- truncated branch of depth 3
|   |   |--- num__fragil >  0.50
|   |   |   |--- num__valor_mxn <= 1518.10
|   |   |   |   |--- truncated branch of depth 5
|   |   |   |--- num__valor_mxn >  1518.10
|   |   |   |   |--- truncated branch of depth 2

```
