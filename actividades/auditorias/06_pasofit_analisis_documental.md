# Análisis de arquitectura — PasoFit

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** Flutter (solo análisis escrito).

## Alcance y procedencia

Análisis documental propio a partir de los hallazgos compartidos por César Enrique Díaz Maldonado y sus colaboradores. **No se dispone aquí del código original del caso y no se ejecutó.** Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/proyectossE/Auditoria_Pasofit_Flutter.md); las prioridades y propuestas siguientes son el análisis de esta entrega. 

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| pantallas/inicio.dart | Se reporta una condición de sesión cuyo rechazo no se ejecuta. | Navegación / seguridad | Centralizar estado de sesión y proteger también las APIs del servidor. | Un guard de navegación no es autorización del backend. | Comparación del diseño del cliente. |
| pantallas/login.dart | Se reporta validación por búsqueda de palabras en una respuesta. | Integración | Interpretar un contrato JSON y estados HTTP explícitos. | Adapter transforma y valida; no basta buscar ok como texto. | Una respuesta parseable no prueba permisos para cualquier dato. |
| estado/oyentes.dart / RelojCubit | Se reportan dos mecanismos para avisar cambios. | Estado | Elegir una fuente de estado y gestionar suscripciones por ciclo de vida. | No duplicar un bus solo para mostrar Observer. | Dos mecanismos pueden convivir si sus responsabilidades están definidas, no por accidente. |
| pantallas/rutina.dart | Se reportan condicionales de cálculo y escrituras desde la pantalla. | Dominio / datos | Separar cálculo y repositorio; Strategy si crecen los algoritmos. | Factory crea objetos, no persiste una rutina. | No introducir abstracciones para una sola fórmula estable. |
| pantallas/rutina.dart / peso.dart | Se reportan dos escrituras sin agrupación ni intento único. | Persistencia local | Transacción local e identificador de operación para reintentos. | Observer no da atomicidad a SQLite. | La sincronización remota necesita su propio contrato de idempotencia. |
| pantallas/inicio.dart / docs/ | Se reportan ocho llamadas consecutivas y documentación bancaria ajena. | Integración / mantenimiento | Caché, tiempos límite y documentación del flujo efectivo. | Circuit Breaker no proporciona datos offline por sí solo. | No confundir una caché antigua con información actual. |

## Decisión de intervención

Conservar las pantallas como referencia y revisar gradualmente estado, repositorio y contratos. 

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «guardar rutina»

El punto de entrada reportado es `pantallas/rutina.dart`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende sesión de ejercicio y logro local. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

Flutter separa widgets y estado; el paquete de estado elegido puede notificar cambios. La persistencia local y el cliente HTTP se encapsulan fuera del widget. La autenticación efectiva de datos remotos pertenece al servidor.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.
