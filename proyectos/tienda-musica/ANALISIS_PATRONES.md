# Análisis de patrones — web y móvil

Alumno: Diego Rivera Cisneros · 22121364. Cada patrón apunta a un archivo real; donde un patrón se cumple solo en parte, se dice.

## Backend (Django)

| Patrón | Dónde | Problema que evita |
|---|---|---|
| **Front Controller** | `tienda/urls.py` + `catalogo/urls.py` | Una sola puerta de entrada HTTP: Django enruta cada URL a su vista, sin un script PHP por pantalla. |
| **MVC (MTV en Django)** | Modelo: `catalogo/models.py`; vista/controlador: `catalogo/views.py`; la «vista» de presentación es JSON, no HTML | Separa datos, reglas de entrada y salida; las vistas no contienen lógica de negocio ni de ML. |
| **Strategy** | `catalogo/niveles.py` (`Nivel`, `Basico`, `Reforzado`, `Premium`) y `catalogo/reglas.py` | Cada nivel de embalaje arma su propio plan (materiales, seguro, horas). Agregar un nivel no toca vistas ni cliente. Las reglas de seguridad son un conjunto aparte, intercambiable. |
| **Repository** (parcial) | `catalogo/models.py` con el ORM de Django (`Producto.objects`, `Pedido.objects`) | Evita SQL repartido. Honestamente: no escribí una clase `Repository` propia; el ORM cumple ese papel y las vistas lo usan directo. Con más consultas convendría extraerlo. |
| **Adapter con interfaz** | `catalogo/recomendador.py` (`RecomendadorIA`, `RecomendadorModelo`, `RecomendadorReglas`, `Sugerencia`) | La vista no sabe si decide un árbol, un bosque o reglas simples: pide `sugerir()` a la interfaz. Cambiar de modelo es cambiar una fábrica. |
| **Factory + caché** | `obtener_recomendador()` (`lru_cache`) y `crear_nivel()` | Se crea el recomendador una vez (cargar el `.joblib` es caro) y se elige la variante por configuración (`RECOMENDADOR`). |
| **Decorator / respaldo (fallback)** | `RecomendadorConRespaldo` | Envuelve al modelo y, si el `.joblib` falta o falla, responde con reglas simples: la tienda sigue vendiendo. |
| **Adapter** | `catalogo/asistente.py`, `adaptar_respuesta` | Cada ruta del asistente (folio, producto, corpus, rechazo) produce datos distintos; la función los traduce al contrato `{intencion, respuesta, confianza, …}` que consume Flutter. |
| **Middleware** | `catalogo/cors.py` | Añade CORS a todas las respuestas sin repetirlo en cada vista; necesario para Flutter web. |
| **Validación en el servidor** | `catalogo/validacion.py` | El cliente puede omitirse (Postman); el servidor nunca confía en lo que Flutter valida. |
| **Composición en el servidor** | `catalogo/envios.py` (`entradas_desde_producto`) | El cliente solo envía producto, cantidad y ciudad; valor, peso y dimensión salen de la base. Nadie puede declarar un piano de \$60,000 con valor \$100 para pagar menos embalaje. |
| **Unidad de trabajo / transacción** | `catalogo/views.py` (`checkout`, `transaction.atomic`) | Una compra con varias líneas crea todos los pedidos y descuenta existencias, o no hace nada si una línea falla. |
| **Pipeline por capas** | `catalogo/asistente.py` (8 capas) | Seguridad → router → memoria → herramientas → permisos → respuesta → observabilidad → evaluación; cada capa se prueba por separado y deja traza. |
| **Control de acceso por rol (ACL)** | `asistente.py` (`_verificar`, índices separados por audiencia) y `views._es_admin` | Público, cliente (su folio con su correo) e interno (token): lo interno nunca entra al índice público, y un folio con dueño no se detalla sin verificar. |
| **Pasarela simulada (Gateway)** | `catalogo/pagos.py` | Aísla el cobro tras una función (`validar_tarjeta`, `cobrar`); cambiar a una pasarela real no toca el checkout. Solo acepta tarjetas de prueba y descarta número y CVV. |
| **Servicio con efectos secundarios aislados** | `catalogo/correos.py` | El correo es un efecto lateral tras la transacción: si falla, la compra ya cobrada no se cancela y el fallo queda registrado. |
| **Servicio geográfico local** | `catalogo/geo.py` | La ubicación del usuario se resuelve con una tabla propia (haversine), sin enviarla a terceros. |

No apliqué Repository formal, Observer ni Circuit Breaker: el sistema es un monolito pequeño y no hay eventos ni servicios externos que lo justifiquen.

## Cliente (Flutter)

| Patrón / idea | Dónde | Problema que evita |
|---|---|---|
| **Facade** | `app/lib/api.dart`, clase `RumboApi` | Las pantallas no conocen HTTP, URLs, JSON ni timeouts; llaman `productos()`, `recomendar()`, `registrar()`, `preguntar()`. |
| **Adapter / mapeo de datos** | `Producto.fromJson`, `Recomendacion.fromJson`, etc. en `api.dart` | Convierte JSON en objetos tipados; un cambio de nombre de campo se corrige en un lugar. |
| **Composición de UI** | `lib/pages/*.dart` (`_Resultado`, `ListTile`, `Card`…) | Pantallas construidas con widgets pequeños en lugar de herencia. |
| **Observer (estado compartido)** | `app/lib/state.dart`, `Tienda` (`ChangeNotifier`) + `TiendaScope` (`InheritedNotifier`) | El carrito y la conversación del asistente viven fuera de las pantallas; al cambiar, se redibujan el contador del carrito, el chat y el resumen sin pasar callbacks por todo el árbol. |
| **Estado local (`State` + `setState`)** | `ListadoPage`, `ProductoPage`, `CarritoPage`, `RecomendarPage` | Cada pantalla gestiona su propia carga, error y resultado (`_cargando`, `_error`); el estado que sobrevive a la navegación va en `Tienda`. |
| **Navegación por pila** | `Navigator.push/pushReplacement/popUntil` | La confirmación reemplaza al formulario para no volver a registrar con «atrás». |
| **Inyección de dependencias** | `TiendaApp(api: …, ubicacion: …)` y `ServicioUbicacion` (`ubicacion.dart`) | Permite probar con un cliente HTTP simulado y un GPS falso (`test/widget_test.dart`), sin depender del dispositivo. |

## Separación cliente/servidor (Proyecto 2)

Los `.joblib` y el corpus **solo viven en el servidor**. Flutter envía texto y recibe JSON; no puede ver ni alterar el modelo, y reentrenar o corregir una regla no exige publicar otra versión de la app. En el cliente cambian pantalla de chat y estados de red; en el servidor, el endpoint `/api/asistente/`, la carga cacheada del modelo y las consultas a la base.

## Recomendador frente a asistente

El **recomendador** decide (embalaje y seguro) usando datos estructurados, un modelo y reglas. El **asistente** interpreta lenguaje, consulta lo ya registrado y orienta. Si se le pregunta qué embalaje poner, **remite** al recomendador (`accion: abrir_recomendador`); si se le pregunta por qué un folio salió así, **lee** `nivel_modelo`, `reglas` y `nivel_final` guardados. No existe ningún camino en el que el asistente calcule un nivel de embalaje por su cuenta.
