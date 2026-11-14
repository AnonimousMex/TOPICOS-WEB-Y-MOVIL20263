# Resultados reproducidos

Python 3.12.13; partición estratificada 80/20, semilla 42.
Los porcentajes de las tablas se expresan como fracciones (0.921 = 92.1%).

## 1. Retrato

| medio_recomendado   |   cantidad |
|:--------------------|-----------:|
| moto                |       4578 |
| bicicleta           |       2796 |
| camioneta           |       1678 |
| dron                |        948 |

## 1. clima

| clima         |   bicicleta |   camioneta |   dron |   moto |
|:--------------|------------:|------------:|-------:|-------:|
| despejado     |      0.3284 |      0.1657 | 0.1352 | 0.3707 |
| lluvia        |      0.0849 |      0.1668 | 0.0000 | 0.7483 |
| viento_fuerte |      0.3169 |      0.1841 | 0.0000 | 0.4990 |

## 1. zona_destino

| zona_destino   |   bicicleta |   camioneta |   dron |   moto |
|:---------------|------------:|------------:|-------:|-------:|
| centro         |      0.5845 |      0.1352 | 0.0000 | 0.2803 |
| periferia      |      0.0088 |      0.1398 | 0.1261 | 0.7253 |
| residencial    |      0.2620 |      0.1462 | 0.1730 | 0.4189 |
| rural          |      0.0000 |      0.4080 | 0.0000 | 0.5920 |

## 1. Límites observados

| medio_recomendado   |   ('peso_kg', 'min') |   ('peso_kg', 'median') |   ('peso_kg', 'max') |   ('volumen_l', 'min') |   ('volumen_l', 'median') |   ('volumen_l', 'max') |   ('distancia_km', 'min') |   ('distancia_km', 'median') |   ('distancia_km', 'max') |
|:--------------------|---------------------:|------------------------:|---------------------:|-----------------------:|--------------------------:|-----------------------:|--------------------------:|-----------------------------:|--------------------------:|
| bicicleta           |               0.1000 |                  1.7600 |               7.9900 |                 0.3000 |                    7.7800 |                39.7000 |                    0.3700 |                       3.4200 |                    7.0000 |
| camioneta           |               0.1000 |                  6.7250 |              80.0000 |                 0.3000 |                   31.3650 |               400.5700 |                    0.4300 |                       8.9900 |                   59.1200 |
| dron                |               0.1000 |                  1.0450 |               2.5000 |                 0.3000 |                    4.2900 |                11.9800 |                    2.0700 |                       9.5350 |                   14.9900 |
| moto                |               0.1000 |                  2.5800 |              24.9300 |                 0.3000 |                   11.2750 |                89.9900 |                    0.3400 |                      10.6300 |                   39.9000 |

## 1. Justificación física

{
  "etiquetas_imposibles": 0,
  "camionetas_cortas": 107,
  "camionetas_grandes": 61,
  "camionetas_refrigeradas": 36,
  "justificadas_union": 95,
  "sin_razon_fisica": 12,
  "periferia_hasta_7_km": 0.022482893450635387
}

## 2. Día y noche

| hora_salida   |   bicicleta |   camioneta |   dron |   moto |
|:--------------|------------:|------------:|-------:|-------:|
| False         |        2739 |        1487 |    948 |   3773 |
| True          |          57 |         191 |      0 |    805 |

## 2. Variable nocturna

|             |     filas |   exactitud |   exactitud_reglas |   precision_dron |   recall_dron |   predice_dron |   imposibles |   confianza_media |
|:------------|----------:|------------:|-------------------:|-----------------:|--------------:|---------------:|-------------:|------------------:|
| base        | 2000.0000 |      0.9210 |             0.9365 |           0.8390 |        0.9053 |       205.0000 |      31.0000 |            0.9254 |
| es_de_noche | 2000.0000 |      0.9295 |             0.9365 |           0.9101 |        0.9053 |       189.0000 |      14.0000 |            0.9295 |

## 3. Confusiones

|                            |   cantidad |
|:---------------------------|-----------:|
| ('moto', 'bicicleta')      |         46 |
| ('camioneta', 'moto')      |         32 |
| ('moto', 'dron')           |         29 |
| ('bicicleta', 'moto')      |         20 |
| ('dron', 'bicicleta')      |         18 |
| ('camioneta', 'bicicleta') |          9 |
| ('camioneta', 'dron')      |          4 |

## 4. Importancia agrupada

|                     |   importancia |
|:--------------------|--------------:|
| distancia_km        |        0.3220 |
| volumen_l           |        0.1929 |
| clima               |        0.1438 |
| refrigerado         |        0.1313 |
| peso_kg             |        0.1263 |
| hora_salida         |        0.0587 |
| fragil              |        0.0199 |
| prioridad           |        0.0031 |
| valor_declarado_mxn |        0.0007 |
| ancho_cm            |        0.0007 |
| largo_cm            |        0.0003 |
| alto_cm             |        0.0003 |
| trafico             |        0.0002 |
| zona_destino        |        0.0000 |

## 4. Ablación

|                     |   exactitud_sin_columna |   cambio |
|:--------------------|------------------------:|---------:|
| distancia_km        |                  0.7930 |  -0.1280 |
| peso_kg             |                  0.9040 |  -0.0170 |
| largo_cm            |                  0.9205 |  -0.0005 |
| ancho_cm            |                  0.9205 |  -0.0005 |
| alto_cm             |                  0.9205 |  -0.0005 |
| volumen_l           |                  0.9060 |  -0.0150 |
| fragil              |                  0.9155 |  -0.0055 |
| refrigerado         |                  0.8785 |  -0.0425 |
| valor_declarado_mxn |                  0.9210 |   0.0000 |
| hora_salida         |                  0.8910 |  -0.0300 |
| prioridad           |                  0.9215 |   0.0005 |
| zona_destino        |                  0.9210 |   0.0000 |
| clima               |                  0.8445 |  -0.0765 |
| trafico             |                  0.9210 |   0.0000 |

## 5. Balanceo

| estrategia        |   entrenamiento |     filas |   exactitud |   exactitud_reglas |   precision_dron |   recall_dron |   predice_dron |   imposibles |   confianza_media |
|:------------------|----------------:|----------:|------------:|-------------------:|-----------------:|--------------:|---------------:|-------------:|------------------:|
| sin_balancear     |       8000.0000 | 2000.0000 |      0.9210 |             0.9365 |           0.8390 |        0.9053 |       205.0000 |      31.0000 |            0.9254 |
| submuestreo       |       3032.0000 | 2000.0000 |      0.8975 |             0.9090 |           0.8894 |        0.9316 |       199.0000 |      29.0000 |            0.9141 |
| repetir_drones    |      10905.0000 | 2000.0000 |      0.9000 |             0.9215 |           0.7280 |        1.0000 |       261.0000 |      54.0000 |            0.9337 |
| pesos_balanceados |       8000.0000 | 2000.0000 |      0.9025 |             0.9155 |           0.7661 |        1.0000 |       248.0000 |      35.0000 |            0.9202 |

## 5. Trampa: prueba balanceada

|               |     filas |   exactitud |   exactitud_reglas |   precision_dron |   recall_dron |   predice_dron |   imposibles |   confianza_media |
|:--------------|----------:|------------:|-------------------:|-----------------:|--------------:|---------------:|-------------:|------------------:|
| no_comparable | 3660.0000 |      0.9175 |             0.9290 |           0.9530 |        0.9093 |       873.0000 |      42.0000 |            0.9154 |

## 6. Costos sin ruido (puntos de la fórmula, no pesos)

|                  |   costo_total |   sobrecosto_porcentaje |
|:-----------------|--------------:|------------------------:|
| optimo           |   242269.9333 |                  0.0000 |
| etiquetas        |   247788.5543 |                  2.2779 |
| modelo_reglas    |   242689.0522 |                  0.1730 |
| entrenado_optimo |   242631.9267 |                  0.1494 |

## 6. Acuerdos

{
  "acuerdo_optimo_etiquetas": 0.9365,
  "modelo_sin_reglas_etiquetas": 0.921,
  "modelo_reglas_etiquetas": 0.9365,
  "modelo_reglas_optimo": 0.981,
  "errores_reglas_contra_etiqueta": 127,
  "errores_reglas_que_son_optimos": 107
}

## 7. Coherencia con reglas

|               |   exactitud |   peso_sin_cambio_factibilidad |   hora_10_a_16 |   fragil_sale_camioneta |   trafico_sale_dron |   casos_peso_comparables |
|:--------------|------------:|-------------------------------:|---------------:|------------------------:|--------------------:|-------------------------:|
| profundidad_8 |      0.9210 |                         2.0000 |         0.0000 |                  0.0000 |              0.0000 |                1936.0000 |
| sin_limite    |      0.8930 |                        94.0000 |        36.0000 |                  2.0000 |              3.0000 |                1936.0000 |

## 7. Contraejemplo de distancia

{
  "cantidad": 1,
  "ejemplo": {
    "original": {
      "distancia_km": 1.95,
      "peso_kg": 24.45,
      "largo_cm": 64.1,
      "ancho_cm": 27.0,
      "alto_cm": 27.8,
      "volumen_l": 48.11,
      "fragil": 1,
      "refrigerado": 0,
      "valor_declarado_mxn": 129.18,
      "hora_salida": 12,
      "prioridad": "normal",
      "zona_destino": "residencial",
      "clima": "lluvia",
      "trafico": "bajo"
    },
    "distancia_reducida": 0.975,
    "optimo_original": "moto",
    "optimo_reducido": "camioneta",
    "costos_original": {
      "moto": 110.47983193277311,
      "camioneta": 112.32
    },
    "costos_reducido": {
      "moto": 105.98991596638655,
      "camioneta": 102.96000000000001
    }
  }
}

## 7. Sensibilidad a valor declarado

{
  "datos_valor_mayor_20000": 43,
  "cambios_modelo_valor": 0,
  "cambios_optimo_valor": 352
}

## 8. Escenarios de cambio

| escenario            |   exactitud_cruda |   exactitud_reglas |   confianza_media |   corregidas |   imposibles_finales |   recomienda_bicicleta |   recomienda_moto |   recomienda_camioneta |   recomienda_dron |
|:---------------------|------------------:|-------------------:|------------------:|-------------:|---------------------:|-----------------------:|------------------:|-----------------------:|------------------:|
| referencia           |            0.9258 |             0.9374 |            0.9254 |       0.0116 |               0.0000 |                 0.3164 |            0.4442 |                 0.1542 |            0.0852 |
| lluvias              |            0.9226 |             0.9308 |            0.9273 |       0.0084 |               0.0000 |                 0.1944 |            0.6140 |                 0.1548 |            0.0368 |
| drones               |            0.8312 |             0.8402 |            0.9259 |       0.0094 |               0.0000 |                 0.3070 |            0.4596 |                 0.1434 |            0.0900 |
| drones_reglas_nuevas |            0.8312 |             0.8402 |            0.9259 |       0.0094 |               0.0000 |                 0.3070 |            0.4596 |                 0.1434 |            0.0900 |

## 8. Reentrenamiento

|    | estrategia                      |   nuevos |   total |   exactitud_reglas |   acuerdo_optimo_nuevo |
|---:|:--------------------------------|---------:|--------:|-------------------:|-----------------------:|
|  0 | solo_nuevos                     |      200 |     200 |             0.7970 |                 0.8284 |
|  1 | viejos_mas_nuevos               |      200 |   10200 |             0.8412 |                 0.8818 |
|  2 | viejos_reetiquetados_mas_nuevos |      200 |   10200 |             0.9302 |                 0.9758 |
|  3 | solo_nuevos                     |      500 |     500 |             0.8612 |                 0.8960 |
|  4 | viejos_mas_nuevos               |      500 |   10500 |             0.8408 |                 0.8806 |
|  5 | viejos_reetiquetados_mas_nuevos |      500 |   10500 |             0.9310 |                 0.9762 |
|  6 | solo_nuevos                     |     1000 |    1000 |             0.9010 |                 0.9370 |
|  7 | viejos_mas_nuevos               |     1000 |   11000 |             0.8410 |                 0.8820 |
|  8 | viejos_reetiquetados_mas_nuevos |     1000 |   11000 |             0.9298 |                 0.9750 |

## Seis CSV: resultados y solapamiento

| archivo   |   filas |   exactitud_total |   baseline_mayoritaria |   filas_vistas_entrenamiento |   exactitud_no_vistas |   clase_desconocida |
|:----------|--------:|------------------:|-----------------------:|-----------------------------:|----------------------:|--------------------:|
| envios1   |   10000 |            0.9537 |                 0.2500 |                            0 |                0.9537 |                   0 |
| envios2   |   10000 |            0.7766 |                 0.3471 |                            0 |                0.7766 |                1616 |
| envios3   |   10000 |            0.9449 |                 0.7374 |                            0 |                0.9449 |                   0 |
| envios4   |   10000 |            0.9269 |                 0.5725 |                            0 |                0.9269 |                   0 |
| envios5   |   10000 |            0.9252 |                 0.4578 |                         8000 |                0.9210 |                   0 |
| envios6   |   10000 |            0.9615 |                 0.6308 |                            0 |                0.9615 |                   0 |
