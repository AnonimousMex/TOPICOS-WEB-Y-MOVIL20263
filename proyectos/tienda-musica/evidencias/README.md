# Evidencias de Tesitura

La misma prueba Dart ejecuta el cliente Flutter en Chrome y Android contra el mismo backend Django y la misma base SQLite de demostración. Web registra el folio `MUS-2026-000006`; Android lo recupera por API y lo consulta con el asistente. Android registra además el folio `MUS-2026-000007`, recuperado después desde el servidor. El proveedor de pagos y el correo real no forman parte de esta prueba.

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

[Resultado web](web/resultado.json) · [Resultado Android](android/resultado.json). Cada ejecución registra su propio pedido y Android consulta además el folio creado en web. Las respuestas reales del recomendador y del chat quedan dentro de cada resultado. [Verificación del servidor compartido](servidor_compartido.json).

El script está en `app/integration_test/entrega_test.dart`; utiliza pantallas de producción y solicitudes HTTP reales. Para el caso de reglas abre el formulario de recomendación con un conjunto reproducible de entradas. El archivo `flujo.json` conserva una ejecución anterior de API y no sustituye estas capturas.

La APK 1.0.1 conserva la URL elegida después de cerrar el proceso y volver a abrir. [Captura en Android](android/12_servidor_persistido.png). Se comprobó con la dirección del host del emulador `http://10.0.2.2:18000/api` y después se restauró la dirección LAN compartida. [Metadatos y SHA-256 de la APK](apk.json).
