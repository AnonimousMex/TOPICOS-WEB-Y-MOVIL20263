# Análisis de arquitectura — Portal universitario

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Marco del caso:** PHP.

## Alcance y procedencia

Análisis documental propio a partir de los hallazgos compartidos por César Enrique Díaz Maldonado y sus colaboradores. **No se dispone aquí del código original del caso y no se ejecutó.** Las rutas y defectos de la tabla son observaciones reportadas en [el documento de referencia](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/Auditoria_Proyecto_Universidad.md); las prioridades y propuestas siguientes son el análisis de esta entrega. 

## Misión 1. Problemas, capas y decisiones

| Evidencia reportada | Problema | Capa | Propuesta | Vecino o confusión | Límite |
| --- | --- | --- | --- | --- | --- |
| index.php / login1.php | Se reportan cookie de bypass y mecanismos de sesión distintos. | Entrada | Centralizar autenticación y autorización; eliminar el bypass. | Middleware; no una excepción por página. | Un cambio de patrón no reemplaza verificar identidad. |
| pagar.php / pagar1.php | Se reportan múltiples ramas de cobro con códigos del banco dentro del trámite. | Dominio / integración | Strategy por forma de cobro y Adapter por proveedor. | Factory elige el cobrador; Adapter traduce el resultado. | No crear una clase por banco si todos usan el mismo contrato. |
| kardex.php / kardex1.php | Se reporta SQL y cálculo de calificaciones mientras se pinta HTML. | Datos / presentación | Consultar datos en servicio/ORM y renderizar un modelo de vista. | Repository no es una plantilla y MVC no se logra con nombres de carpeta. | Un repositorio adicional puede sobrar en una consulta sencilla con ORM. |
| pagar1.php | Se reportan escrituras sucesivas y correo sin transacción explícita. | Aplicación / datos | Transacción local, outbox y consumidor idempotente. | Observer no vuelve atómicos el saldo y el alta. | La transacción no incluye al banco externo. |
| api.php | Los apuntes reportan eval y lectura de una ruta recibida del cliente. | Seguridad | Eliminar ejecución arbitraria y limitar operaciones a una API explícita. | Ningún patrón GoF sanea una API que permite ejecutar código recibido. | No ejecutar esta muestra en un servidor accesible. |
| documentacion/ / bd/ | El diagrama y los scripts describen esquemas diferentes. | Modelo / mantenimiento | Inventariar esquema efectivo, aclarar cuál versión manda y migrar con pruebas. | No construir Adapter para un XML que el código no usa. | No borrar tablas solo por parecer antiguas sin conocer sus consumidores. |

## Decisión de intervención

Reorganizar gradualmente desde una entrada protegida y un caso de pago caracterizado; conservar las reglas verificadas. No recomendaría una reescritura total sin pruebas y plan de migración: las versiones duplicadas y el esquema contradictorio hacen difícil saber qué comportamiento se perdería.

La prioridad inicial es controlar acceso y parametrizar consultas; después, probar consistencia y duplicados; finalmente, optimizar latencia y retirar duplicación. La validación de entradas y los parámetros SQL son controles concretos: añadir una clase Repository sin ellos no corrige una inyección.

## Misión 2. Recorrido de «pagar inscripción»

El punto de entrada reportado es `pagar1.php`. El recorrido propuesto separa recepción, permisos y negocio:

```text
Interfaz → entrada del framework → autenticación y autorización
         → validación del contrato → caso de uso
         → idempotencia → algoritmo de dominio / Adapter externo
         → transacción local → COMMIT → notificación
```

La unidad local comprende pago, recibo y alta de materias. Deben existir restricciones o mecanismos de concurrencia para que dos solicitudes no consuman el mismo recurso. La idempotencia se registra en almacenamiento compartido, no solo desactivando el botón.

Si hay un banco o servicio remoto, la llamada ocurre fuera de una transacción SQL prolongada. Se conserva el intento y su clave, se traduce el resultado mediante el Adapter y se concilian respuestas ambiguas. Un rollback local no cancela el efecto externo. Los avisos se publican tras el commit; una outbox evita perder el evento y un consumidor idempotente evita duplicarlo.

## Misión 3. Políticas transversales y marco

PHP no aporta por sí solo un router o una transacción automática por petición. Puede usarse un framework, o una entrada pequeña que llame a servicios; la transacción pertenece al driver/ORM y no al HTML.

El orden es: identificar petición para registrar incluso rechazos, autenticar, autorizar, validar y ejecutar. La disponibilidad concreta de habitación, asiento o mecánico es una regla del caso de uso y debe comprobarse también al confirmar la transacción; una comprobación temprana en un filtro no evita carreras. La bitácora no debe almacenar contraseñas, tarjetas ni secretos.

Las políticas comunes no eligen el algoritmo de precio, ni construyen el HTML, ni guardan el detalle de la operación. Su función es establecer condiciones de entrada y registrar el resultado.
