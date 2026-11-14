# Análisis de arquitectura — Cinerex

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** Django.

## Alcance y procedencia

Análisis documental propio a partir de los hallazgos compartidos por César Enrique Díaz Maldonado y sus colaboradores. **No se dispone aquí del código original del caso y no se ejecutó.** Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/proyectossE/Auditoria_Cinerex_Django.md); las prioridades y propuestas siguientes son el análisis de esta entrega. 

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| taquilla/views.py::login | Se reporta SQL interpolado con credenciales. | Datos / seguridad | Consultas parametrizadas y autenticación del framework. | Repository no evita SQLi si sigue concatenando entradas. | Validar formato no sustituye parámetros. |
| cinerex/settings.py / taquilla/cadena.py | Se reporta autenticación desactivada y una cadena no conectada. | Entrada | Restituir middleware y permisos por operación. | Una clase Handler sin integrarse no protege ninguna ruta. | AuthenticationMiddleware identifica; la autorización debe exigirse también. |
| taquilla/views.py::cartelera | Se reportan nueve llamadas consecutivas a módulos externos. | Integración | Presupuesto de espera y degradación por componente. | Retry sin límite aumenta la espera. | No crear un microservicio por cada dato de la cartelera. |
| taquilla/templatetags/sql_cine.py | Se reporta SQL desde la plantilla y consultas por película. | Datos / presentación | Preparar el modelo de vista y precargar relaciones. | Mover HTML de archivo no elimina N+1. | Medir consultas antes de añadir caché. |
| taquilla/views.py::comprar | Se reportan varias escrituras sin atomicidad ni clave de intento. | Aplicación / datos | Transacción local, unicidad de asiento por función e idempotencia. | Observer no impide vender el mismo asiento dos veces. | Una consulta previa de disponibilidad no protege contra carreras. |
| docs/ / settings.py | Se reporta documentación de otro dominio y configuración sensible en código. | Mantenimiento | Documentar cine y externalizar secretos; rotarlos si fueron expuestos. | Un archivo de constantes sigue estando en Git. | No copiar valores sensibles al informe. |

## Decisión de intervención

Conservar el proyecto Django y reemplazar por etapas la entrada insegura y la compra monolítica. El framework ya ofrece una base; las pruebas de concurrencia y permisos deben preceder al cambio de flujo.

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «comprar boleto»

El punto de entrada reportado es `taquilla/views.py::comprar`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende boleto, asiento y consumos. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

Django aporta enrutamiento, middleware, autenticación, ORM y transacciones. No escribiría una cadena GoF paralela al framework; `transaction.atomic` debe envolver los cambios locales, y una restricción de base debe proteger el asiento.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.
