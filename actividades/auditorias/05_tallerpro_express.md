# Análisis de arquitectura — TallerPro

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** Express.

## Alcance y procedencia

Análisis documental propio a partir de los hallazgos compartidos por César Enrique Díaz Maldonado y sus colaboradores. **No se dispone aquí del código original del caso y no se ejecutó.** Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/proyectossE/Auditoria_Tallerpro_Express.md); las prioridades y propuestas siguientes son el análisis de esta entrega. 

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| cadena/Handler.js | Se reporta una cadena Auth → Bitácora → Cobro usada solo en /nueva. | Entrada | Aplicar políticas comunes desde routers o middleware en todas las rutas protegidas. | Tener Handler no prueba que cubra toda la aplicación. | No interceptar rutas públicas con requisitos que no les corresponden. |
| AuthHandler / login | Se reporta aceptación de cookie de bypass y SQL concatenado. | Seguridad | Eliminar bypass, parametrizar y verificar permisos. | Un patrón bien dibujado no hace seguro su contenido. | Conservar la estructura solo después de revisar cada política. |
| app.js::/ | Se reportan ocho llamadas externas consecutivas. | Integración | Acotar tiempo y permitir respuesta parcial. | Retry agresivo amplifica fallos. | BFF solo si la agregación necesita adaptación por cliente. |
| CobroOrden | Se reporta costo y banco dentro del handler final. | Dominio / integración | Caso de uso, Strategy de servicio y Adapter del banco. | El middleware no debe decidir precio por cada ruta. | Un cálculo fijo no requiere una jerarquía extensa. |
| CobroOrden | Se reporta asignación de mecánico y varias escrituras sin atomicidad. | Datos | Transacción, control concurrente del cupo y clave de intento. | Consultar libre antes de escribir no garantiza exclusión. | La garantía debe mantenerse aunque dos peticiones lleguen juntas. |
| app.js / app.old.js / docs/ | Se reportan SQL por fila, configuración embebida y una versión vieja duplicada. | Mantenimiento / datos | Agrupar consultas, externalizar secretos y usar historial Git. | Una copia old no es una política de recuperación. | Comprobar consumidores antes de retirar un archivo. |

## Decisión de intervención

Conservar la intención de la cadena existente, eliminar el bypass y migrarla a middleware compartido. Luego extraer el caso de orden, control de cupo y transacción. No reescribiría todo Express porque ya existe un flujo que puede caracterizarse.

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «abrir orden de taller»

El punto de entrada reportado es `cadena/Handler.js::CobroOrden`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende orden, uso de refacciones y ocupación del mecánico. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

Express aporta middleware y routers, pero no una transacción de base automática. Esa operación se configura con el driver/ORM elegido usando la misma conexión durante todas las escrituras.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.
