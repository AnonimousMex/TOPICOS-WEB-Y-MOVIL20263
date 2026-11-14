# Análisis de arquitectura — Hotel Luna

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** Spring.

## Alcance y procedencia

Análisis documental propio a partir de los hallazgos compartidos por César Enrique Díaz Maldonado y sus colaboradores. **No se dispone aquí del código original del caso y no se ejecutó.** Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/proyectossE/Auditoria_Hotelluna_Spring.md); las prioridades y propuestas siguientes son el análisis de esta entrega. No se cambian nombres para atribuirse la auditoría original ni se inventan líneas o capturas.

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| LoginCtrl.java / CheckinCtrl.java | Se reportan consultas concatenadas con correo o reserva. | Datos / seguridad | Parámetros de consulta y controles de acceso por reserva. | Repository es organización; la parametrización es el control ante SQLi. | Un id numérico no demuestra que pertenezca al huésped. |
| FrontControllerServlet.java | Se reportan una cadena vacía y una entrada que se superpone con Spring. | Entrada | Usar DispatcherServlet y la cadena de seguridad del framework. | Otro Front Controller casero no añade protección. | La superposición de mappings debe verificarse al ejecutar; no se afirma cuál gana. |
| ReservaCtrl.java | Se reporta precio por condicionales y XML de pago en el controlador. | Dominio / integración | Servicio de reserva, Strategy para tarifas variables y Adapter bancario. | Factory no calcula una tarifa ni traduce el protocolo. | Si una tarifa es solo configuración, una tabla puede bastar. |
| ReservaCtrl.java | Se reportan tres escrituras sin unidad transaccional. | Datos | Transacción del servicio, bloqueo o restricción de disponibilidad e idempotencia. | Observer no reserva inventario. | Un @Transactional en documentación no prueba que esté activo. |
| FacturaSql.java | Se reporta mezcla de HTML y consultas por reserva. | Presentación | Preparar datos y renderizar una plantilla, agrupando las consultas. | Facade no elimina automáticamente N+1. | Comprobar la consulta generada antes de prometer una mejora. |
| docs/ / application.properties | Se reportan documentos de inventario de piezas y credenciales embebidas. | Mantenimiento | Actualizar modelo del hotel y cargar secretos fuera del repositorio. | Un perfil de configuración no protege un secreto publicado. | El informe no reproduce contraseñas. |

## Decisión de intervención

Retirar la entrada duplicada y mantener el flujo estándar de Spring. Después extraer un servicio transaccional de reserva. Conservar reglas de tarifa caracterizadas; no mover todo a microservicios por la existencia del servlet duplicado.

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «reservar habitación»

El punto de entrada reportado es `ReservaCtrl.java`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende reserva, disponibilidad de habitación y servicios asociados. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

Spring MVC administra la entrada; Spring Security, filtros; la transacción declarativa se aplica desde un servicio invocado a través del mecanismo correspondiente. Hay que comprobar los límites y no asumir que una anotación sobre una llamada interna crea una transacción.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.

## Cómo se comprobaría al recibir el original

- Comparar rutas efectivas con los middleware registrados; una clase sin conectar no prueba protección.
- Ejecutar una solicitud sin sesión y otra con un usuario sin permisos, verificando rechazo antes de cualquier efecto.
- Repetir el mismo intento y lanzar dos solicitudes concurrentes sobre el mismo recurso: debe quedar un resultado coherente sin duplicados.
- Simular caída del proveedor y fallo de la última escritura: conservar estado reconciliable y consultas independientes disponibles.
- Medir consultas y latencia; contrastar esquema real con la documentación.

Estas verificaciones son un plan pendiente, no resultados obtenidos. El caso del portal también puede contrastarse con el análisis de código publicado en los [apuntes del profesor](https://ealcaraz85.github.io/topicoswebmobil/#actividades).
