# Notas de implementación

Diego Rivera Cisneros · 22121364. Las secciones siguen los cinco bloques de la actividad; las evidencias registran la fecha real de la comprobación, sin atribuir fechas históricas a cada bloque.

## Día 1: los siete inconvenientes

| Inconveniente | Qué aporta Django | Qué se implementó | Qué no se duplicó |
|---|---|---|---|
| Políticas repetidas en cada trámite | Middleware y despacho HTTP | Sesión y CSRF configurados una vez | Un front controller manual por URL |
| Variaciones de medio e idioma de IA | No define el dominio de la empresa | Cuatro estrategias, fábrica simple y Adapter JSON/XML | Jerarquías de Factory Method sin familias de trámites |
| SQL dentro del seguimiento | ORM y motor de plantillas | Consulta del pedido en el servicio; plantilla solo presenta | Consultas dentro del HTML |
| Aviso que rompe registro y doble clic | Transacciones, restricciones únicas y `on_commit` | Pedido atómico, intento idempotente y aviso posterior | Confundir Observer con atomicidad |
| HTML y teléfono piden datos distintos | Vistas y serialización JSON | HTML y JSON mínimo del mismo folio | Duplicar el pedido por cliente o llamar doce APIs |
| IA caída bloquea lo ya guardado | Respuestas HTTP y manejo de errores | Alta responde 503; consulta guardada no llama al proveedor | Recalcular la IA al consultar cada pedido |
| Arquitectura excesiva para un trámite pequeño | Rutas y servicios de aplicación sencillos | Un monolito local con responsabilidades separadas | Event Sourcing, CQRS y Redux global |

`urls.py` forma parte del despacho de entrada del framework; la vista concreta atiende una página o recurso. No hace falta crear otra clase Front Controller. Una plantilla no debe ejecutar SELECT: recibe el pedido ya consultado y lo representa.

## Día 2: alta y PRG

La petición POST llega por middleware, el resolver encuentra `views.crear`, y esa vista llama `servicios.registrar_pedido`. El servicio valida peso, distancia, destino e intento; adapta la sugerencia, planea y guarda. La vista redirige al GET del folio. Recargar ese GET no registra otro pedido.

El resolver, la petición y las respuestas los instancia Django; no son clases GoF escritas por la aplicación. La vista no conoce las clases de cada vehículo y no calcula ETA por su cuenta.

PRG evita repetir el POST al recargar la pantalla final. La restricción única de `intento` cubre además dos POST del mismo intento. Si se reusa el intento con otros datos, el servicio rechaza la operación. Para un cobro externo haría falta conservar esa identidad ante el proveedor y conciliar estados; esta práctica no cobra.

## Día 3: Strategy, Adapter y creación

Strategy separa cómo planea cada medio: capacidad, velocidad y alcance se resuelven en su objeto. No organiza la navegación ni los estados del pedido.

Adapter traduce `route_hint` o `vehicle` a `Sugerencia(medio, motivo)` antes del dominio. No es Facade: está cambiando el idioma del colaborador, no simplificando un trámite interno.

La fábrica `crear_medio` selecciona una de las cuatro estrategias. Una fábrica simple es suficiente; no hay familias de logística que sobrescriban un gancho de creación para justificar Factory Method.

El caso de uso sigue Adapter → fábrica → Strategy. Agregar un triciclo exigiría su estrategia y registro en la fábrica, además de la política o traducción que lo pueda sugerir; no obliga a editar la plantilla o la vista. El contrato de `Sugerencia` y el trámite se conservan.

## Día 4: persistencia y caída parcial

La plantilla usa los valores de `pedido`. Las pruebas verifican una sola consulta para la página y una para su representación JSON. El dibujo de ruta es un esquema, no navegación real.

`transaction.atomic` delimita la escritura local; `transaction.on_commit` programa el aviso después del éxito. La prueba del aviso comprueba que el pedido existe y que ya se salió de la transacción cuando ocurre el aviso. Un fallo simulado del aviso se registra sin deshacer el pedido.

El checkbox de caída simula que el proveedor no responde al nuevo trámite; el alta devuelve 503 con una explicación. La consulta de un folio anterior no invoca al proveedor. La prueba también sustituye el proveedor por uno que siempre falla y comprueba que HTML y JSON guardados siguen respondiendo.

No se guarda el pedido en una variable global. SQLite es suficiente para este laboratorio de un proceso; Rumbo y la práctica de réplicas utilizan PostgreSQL para sus respectivos escenarios.

## Día 5: el mismo folio y defensa

El panel y `/api/pedidos/<folio>` consultan el mismo registro. El JSON contiene solo `folio`, `estado` y `eta`, mientras el HTML añade destino, medio, motivo y esquema. Es una separación de representación; no son dos pedidos ni dos servidores.

Guion de demostración: crear un pedido, comprobar la redirección y el folio, abrir su JSON, repetir el intento y observar el mismo folio, simular IA caída y volver al folio guardado. Explicar después qué se toca al agregar un medio y por qué el correo no pertenece a la transacción.

Se dejaron fuera autenticación de usuarios, pagos externos, despliegue y event sourcing: el alcance de esta actividad es una aplicación web local y un contrato JSON, no una plataforma de producción.

Fuente: [Cinco días — Estudiar, pensar e implementar](https://ealcaraz85.github.io/topicoswebmobil/#org287b5d9).
