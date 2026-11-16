# Evidencias de Tesitura

La misma prueba Dart ejecuta el cliente Flutter en Chrome y Android contra una base de demostración separada. Registra un pedido y consulta ese folio con el asistente. El proveedor de pagos y el correo real no forman parte de esta prueba.

| Caso | Web | Android |
|---|---|---|
| Catálogo | [Captura](web/01_catalogo.png) | [Captura](android/01_catalogo.png) |
| Detalle | [Captura](web/02_producto.png) | [Captura](android/02_producto.png) |
| Entradas | [Captura](web/03_entradas.png) | [Captura](android/03_entradas.png) |
| Humedad y riesgo | [Captura](web/04_condiciones.png) | [Captura](android/04_condiciones.png) |
| Recomendación | [Captura](web/05_recomendacion.png) | [Captura](android/05_recomendacion.png) |
| Corrección por reglas | [Captura](web/06_reglas.png) | [Captura](android/06_reglas.png) |
| Registro y folio | [Captura](web/07_folio.png) | [Captura](android/07_folio.png) |
| Chat: saludo | [Captura](web/08_chat_saludo.png) | [Captura](android/08_chat_saludo.png) |
| Chat: consulta del folio | [Captura](web/09_chat_folio.png) | [Captura](android/09_chat_folio.png) |
| Chat: dominio | [Captura](web/10_chat_dominio.png) | [Captura](android/10_chat_dominio.png) |
| Chat: fuera de dominio | [Captura](web/11_chat_fuera_dominio.png) | [Captura](android/11_chat_fuera_dominio.png) |

[Resultado web](web/resultado.json) · [Resultado Android](android/resultado.json). Los folios difieren porque cada ejecución registra su propio pedido; las respuestas reales del recomendador y del chat quedan dentro de cada resultado.

El script está en `app/integration_test/entrega_test.dart`; utiliza pantallas de producción y solicitudes HTTP reales. Para el caso de reglas abre el formulario de recomendación con un conjunto reproducible de entradas. El archivo `flujo.json` conserva una ejecución anterior de API y no sustituye estas capturas.
