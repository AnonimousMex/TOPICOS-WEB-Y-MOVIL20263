# Misiones 1–8 — Plataforma de entregas

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  



Caso de estudio: empresa de mensajería descrita en los apuntes.

## Misión 1. La plataforma no es un patrón

| Problema | Capa | Patrón | Fuerza concreta | Vecino descartado | Cuándo no aplicaría |
| --- | --- | --- | --- | --- | --- |
| Sesión duplicada en los trámites | Entrada | Front Controller y middleware | Una política debe cubrir todas las rutas protegidas. | Page Controller aislado mantiene las copias. | Una ruta pública no requiere autenticación, aunque conserve el enrutador. |
| Selección y planeación de varios medios | Dominio | Strategy y fábrica simple | Agregar un vehículo sin reescribir el caso de uso. | State cambia conducta por ciclo de vida. | Una sola operación estable puede ser una función. |
| IA con JSON o XML propio | Integración | Adapter | Convertir `route_hint` al contrato de sugerencia. | Facade no resuelve necesariamente la incompatibilidad. | Proveedor y dominio con un contrato idéntico no necesitan traducción adicional. |
| SQL dentro de mapa y reporte | Datos / presentación | Repository, Service Layer y Template View | Reutilizar la consulta y presentar datos listos. | Cambiar de motor de plantillas no quita el SQL de la vista. | Un CRUD pequeño puede usar directamente el ORM desde un servicio sin repositorio adicional. |
| Cobro, alta y avisos acoplados | Aplicación / datos | Unit of Work, idempotencia y eventos posteriores al commit | Impedir estados locales a medias y duplicados. | Observer no revierte escrituras ni cobros externos. | No hace falta cola si no existen efectos secundarios, pero sigue siendo necesaria la consistencia. |
| Doce consultas de inicio y terceros caídos | Borde / integración | Recurso agregado o BFF; Timeout y Circuit Breaker | Reducir viajes y acotar fallos de IA/mapa. | Factory no agrega respuestas y Retry no cura una caída sostenida. | BFF separado sobra si un recurso común satisface a todos. |

## Misión 2. Una petición, varios patrones

```text
POST /pedidos + Idempotency-Key
  → entrada del framework
  → middleware: correlación, autenticación, autorización, límites
  → controlador: validar y convertir el JSON
  → registrarPedido(): reservar intento idempotente
      → Adapter IA: obtener Sugerencia o alternativa segura
      → reglas: descartar medios inviables
      → fábrica: construir estrategia del medio elegido
      → Strategy: calcular el plan
      → transacción local: pedido + estado de pago + evento outbox
  → COMMIT → publicador → cola → notificaciones
  → 201 con folio y representación del pedido
```

El caso de uso coordina; el controlador no interpreta códigos de la IA. La fábrica hace el `new`; la estrategia ejecuta la planeación. La atomicidad cubre las escrituras de la misma base. Si hay cargo externo, el intento se registra antes, se cobra con la misma clave fuera de una transacción larga y se concilia por respuesta o webhook. Un timeout bancario deja un estado pendiente de confirmación; no autoriza un segundo cargo con una clave nueva. El correo ocurre después del commit y puede reintentarse.

## Misión 3. Políticas transversales

Front Controller corresponde cuando varias URLs deben compartir recepción y despacho: evita que una página olvidada omita la política. Spring ofrece `DispatcherServlet` y filtros de seguridad; Laravel, su entrada HTTP y middleware; Express, la aplicación y los routers con middleware. No se construye un enrutador paralelo.

Registraría primero un identificador de petición sin datos sensibles; después autenticaría y autorizaría; registraría el resultado del intento, incluso los rechazos; finalmente ejecutaría el caso de uso. Cobrar antes de autenticar produce un efecto externo antes de saber si el usuario podía ordenar el pago. Los filtros no eligen el vehículo ni calculan tarifas: eso depende de cada pedido.

## Misión 4. Strategy, Adapter y Factory

- **Strategy:** cada vehículo planea el traslado mediante la misma operación. En Java puede expresarse con una interfaz y clases; en JavaScript con funciones u objetos que cumplen un contrato.
- **Adapter:** transforma `route_hint: "bike"` en `Sugerencia{medio: "bici", motivo: ...}`, valida valores desconocidos y conserva la causa de un fallo. No es una Facade porque la dificultad es el vocabulario incompatible.
- **Factory:** crea el medio a partir de un identificador validado. `MedioFactory.crear("dron")` con un `switch` es una fábrica simple. Factory Method sería pertinente si varias clases de logística comparten un proceso y cada subclase decide el producto mediante un método sobrescrito. No se necesita esa jerarquía para un solo selector.

## Misión 5. Atomicidad y avisos

Unit of Work delimita pago registrado y alta dentro de la base; una restricción única protege el identificador del intento. Si el banco es externo, no hay una transacción SQL que lo abarque: se necesitan estados de pago, idempotencia del proveedor, conciliación y compensaciones si procede.

Observer o eventos separan correo, repartidor y estadísticas. Para entrega confiable, el evento se guarda en una outbox junto al pedido y se procesa con consumidores idempotentes. El doble clic se resuelve sobre `POST /pagos` o el intento de pago del pedido, reutilizando la clave para el mismo contenido y rechazando su reutilización con otro importe. Desactivar el botón solo mejora la interfaz.

## Misión 6. Clientes y colaboradores inestables

Gateway aplica políticas comunes; BFF agrega datos para un cliente. Pueden coexistir, pero empezaría con un único recurso de pedido y agregaría BFF solo si las necesidades divergen de verdad. `GET /pedidos/{folio}` consulta; `POST /pedidos` crea. `/asignar` oculta el recurso si se usa como URL aislada para todo; una asignación con identidad propia puede expresarse como recurso subordinado, por ejemplo `POST /pedidos/{folio}/asignaciones`.

Timeout acota cada llamada; Circuit Breaker deja de insistir temporalmente; Retry se limita a fallos transitorios con presupuesto y espera. No se reintenta un cobro ambiguo sin idempotencia ni un error de validación. Consultar un pedido persistido no debe depender de la IA. Para una guía PDF bastan autorización, consulta y renderizado; Event Sourcing y un estado global complejo no se justifican por ese requisito.

## Misión 7. Lo que ya aporta el marco

| Intención | Spring | Express | Qué no reescribir |
| --- | --- | --- | --- |
| Entrada | `DispatcherServlet` y mappings | `app` y routers | Un servlet o dispatcher paralelo. |
| Políticas | Filter chain / Spring Security | Middleware ordenado en `app.use` y routers | Una cadena GoF duplicada sin conectar. |
| Unidad de trabajo | Transacción del servicio con `@Transactional` | API transaccional del driver u ORM elegido | Express por sí solo no trae ORM ni transacciones. |
| Observer en la SPA | Estado/eventos del frontend; Spring no administra el navegador | Estado/eventos del frontend; Express no administra el navegador | Un bus casero si la herramienta de interfaz ya cubre el caso. |

## Misión 8. El mismo pedido en Android

Elijo Android para el razonamiento, sin implementar una app. `estado`, `eta` y `posicion` viven en un ViewModel para sobrevivir a la recreación de la pantalla, respaldados por repositorio y caché local. ViewModel no guarda referencias a una Activity ni hace SQL o transporte HTTP directamente. Para sobrevivir a la muerte del proceso se persiste lo necesario; ViewModel por sí solo no basta.

Un repositorio con fuente remota y local permite consultar el último pedido sin red, mostrando la fecha de actualización. Circuit Breaker puede evitar llamadas reiteradas, pero no sustituye la caché. Para un pago pendiente se conserva un comando con clave estable y estado; WorkManager puede reintentarlo cuando haya red, aunque la confirmación real pertenece al servidor. No se muestra «pagado» solo por encolarlo.

No copiaría BLoC a Android para igualar nombres: usaría las herramientas del entorno y compartiría contratos de API y reglas del servidor. Las doce consultas de inicio se resuelven con agregación/BFF, no con Factory.

**Fuente:** [misiones y rúbrica del profesor](https://ealcaraz85.github.io/topicoswebmobil/#actividades). 

Referencias de los mecanismos nativos: [middleware de Express](https://expressjs.com/en/guide/using-middleware/), [transacciones en Django](https://docs.djangoproject.com/en/6.0/topics/db/transactions/) y [ViewModel de Android](https://developer.android.com/topic/libraries/architecture/viewmodel).
