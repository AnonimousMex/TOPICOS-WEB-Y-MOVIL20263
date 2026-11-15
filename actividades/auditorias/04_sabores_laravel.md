# Análisis de arquitectura — Sabores

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** Laravel.

## Alcance y procedencia

Análisis documental de los hallazgos publicados por César Enrique Díaz Maldonado y sus colaboradores, sin ejecución del código original. Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/proyectossE/Auditoria_Sabores_Laravel.md); las prioridades y propuestas siguientes son el análisis de esta entrega.

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| routes/web.php | Se reportan rutas que no utilizan los middleware escritos. | Entrada | Conectar auth y permisos por rol a los grupos de rutas adecuados. | La existencia de un archivo Authenticate no prueba cobertura. | Una ruta pública puede quedar sin auth, pero no un dato privado. |
| RepartoController.php / LoginController.php | Se reporta acceso por cookie de bypass. | Seguridad | Eliminar el bypass y utilizar sesión verificada en servidor. | No confiar en un booleano enviado por el navegador. | Una cookie firmada tampoco reemplaza autorización actual. |
| PedidoController.php | Se reportan cálculo de envío y XML bancario dentro del controlador. | Dominio / integración | Caso de uso y estrategias; Adapter para la pasarela. | Factory selecciona, no sustituye todo el caso de uso. | Mantener reglas simples como datos cuando sea suficiente. |
| PedidoController.php | Se reporta guardado de pedido y detalle sin operación atómica. | Datos | Transacción local e intento único; publicar eventos tras el commit. | Observer no asegura que exista el detalle. | La cola debe procesar duplicados de forma idempotente. |
| ResenaController.php / MenuController.php | Se reporta SQL armado con la entrada. | Datos / seguridad | Query builder con parámetros y permisos del recurso. | Limpiar texto a mano no cubre todas las entradas SQL. | No usar consultas raw con interpolación. |
| .env / documentacion/ | Se reporta configuración compartida y documentos de otro dominio. | Configuración | Versionar solo .env.example sin valores reales y describir el negocio efectivo. | Mover un secreto a .env y commitearlo no lo externaliza. | No se asume que un valor de ejemplo sea una credencial real. |

## Decisión de intervención

Corregir de forma incremental: conectar middleware, eliminar bypass, caracterizar la compra y extraer la transacción. La estructura de Laravel ya puede aprovecharse; la clase FrontController aislada no aporta valor si no participa en el flujo.

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «crear pedido de comida»

El punto de entrada reportado es `PedidoController.php`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende pedido, detalle y asignación de reparto. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

Laravel aporta router, middleware, autenticación y `DB::transaction`. El controlador delega el pedido a un servicio; no hace falta un segundo router ni reimplementar el contenedor de dependencias.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.
