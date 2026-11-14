# Misión 1

| El problema en corto | Capa | Patrón que lo arregla | Por qué este y no el vecino más fácil de confundir | Cuándo no aplicaría |
| :--- | :--- | :--- | :--- | :--- |
| **1. El mismo código de sesión pegado en 40 archivos.** | Políticas Transversales / Presentación | **Intercepting Filter** | Rechazamos **Template** porque no estamos armando una estructura visual base, sino interceptando la petición como un "cadenero" para validar seguridad antes de entrar a la lógica. | No aplica si la regla es de negocio específica de un solo módulo (ej. validar si el alumno tiene saldo). Esto solo es para reglas que aplican a *todas* las peticiones. |
| **2. Un código de 200 líneas lleno de "IFs" para cobrar.** | Aplicación / Dominio | **Strategy** | Rechazamos **State** porque el pago no está cambiando de estado (de 'pendiente' a 'pagado'), sino que estamos eligiendo el algoritmo o "caja de cobro" (SPEI vs Tarjeta) desde el inicio. | No aplica si la diferencia entre métodos es mínima (ej. solo cambia una variable como el correo de destino). Strategy es para cuando toda la *lógica/algoritmo* cambia. |
| **3. El banco usa códigos raros y nosotros no.** | Integración | **Adapter** | Rechazamos **Facade** porque Facade agrupa y resume varios pasos complejos en uno solo, mientras que Adapter literalmente traduce un idioma (código del banco) a otro (nuestro código) uno a uno. | No aplica si tienes control de ambos sistemas y apenas los vas a construir. Ahí mejor los diseñas para que hablen el mismo idioma desde el inicio sin adaptadores. |
| **4. Las consultas a la BD están revueltas en el diseño.** | Datos | **Repository** | Rechazamos **Active Record** porque Active Record amarra la tabla directamente a la clase. Repository esconde todo el SQL como un "archivero" externo, dándonos consultas más limpias. | No aplica en aplicaciones extremadamente pequeñas o prototipos de CRUD simple, donde crear interfaces y repositorios es demasiada burocracia técnica sin valor. |
| **5. Si falla el correo, no se guarda el pago.** | Aplicación / Dominio | **Observer + Unit of Work** | Unit of Work delimita una transacción para los cambios locales en la base de datos. Elegimos **Observer** y no un simple *Decorator* porque queremos lanzar un evento ("¡Ya pagó!") y que el correo se procese después del commit mediante una cola; Observer por sí solo no garantiza asincronía. | No aplica si la regla de negocio exige que el recibo llegue por correo de forma *obligatoria* para dar el pago por bueno; habría que modelar un estado pendiente y confirmar la entrega con reintentos; no es obligatorio mantener una petición HTTP abierta. |
| **6. La app del celular hace 12 peticiones para abrir.** | Presentación (API) | **BFF (Backend for Frontend)** | Rechazamos un **API Gateway** genérico. El Gateway suele ser solo un enrutador de tráfico, mientras que el BFF empaqueta y transforma datos a la medida exacta de esa pantalla del celular. | No aplica si solo tienes una plataforma (ej. solo Web) o si todos tus clientes (Web y Móvil) consumen exactamente la misma cantidad de datos. Sería meter una capa extra sin sentido. |

<br>

# Misión 2: El viaje del pago 

1. **La Recepcionista (Front Controller):** El alumno da clic en pagar. El sistema recibe esa petición en un solo lugar central y decide a qué parte del código mandarla.
2. **El de Seguridad (Intercepting Filter):** Antes de hacer cualquier cosa, un filtro revisa rápido si el alumno tiene su sesión activa. Si todo está bien, lo deja pasar.
3. **El que toma la orden (Controlador MVC / DTO):** Agarra los datos crudos que mandó el alumno (monto, tarjeta) y los empaqueta bonito para que la lógica de negocio los pueda procesar sin errores.
4. **La Caja Fuerte (Unit of Work):** Registramos un intento de pago con una clave de idempotencia única y cambios locales atómicos. El rollback solo revierte la base de datos local: no deshace un cobro bancario. No mantenemos la transacción abierta mientras esperamos al banco.
5. **La Terminal de Cobro (Strategy):** El sistema revisa con qué quiere pagar el alumno y saca la herramienta correcta (la clase de SPEI o la de Tarjeta).
6. **El Traductor (Adapter):** Nos comunicamos con el banco. Como el banco habla otro idioma técnico, el adaptador traduce su respuesta. Reutilizamos la misma clave de idempotencia en los reintentos si el proveedor la admite. Ante un timeout, consultamos el estado o conciliamos por webhook antes de intentar otro cobro.
7. **El Archivero (Repository):** Ya que tenemos el dinero seguro, actualizamos el estado del pago en una transacción local, con una restricción única para evitar duplicados. Si el banco cobró y el guardado falla, conciliamos el estado; si corresponde cancelar el cobro, usamos una compensación explícita.
8. **El Megáfono (Observer):** Ya quedó todo guardado. En lugar de hacer esperar al alumno viendo una ruedita de carga, el sistema grita internamente: "¡Pago exitoso!". Guardamos también un evento en una outbox dentro de la misma transacción. Un proceso lo publica en una cola y un worker envía el recibo con reintentos e idempotencia, mientras el alumno ya ve la confirmación.

## Referencias técnicas

- [Idempotencia en una API de pagos — Stripe](https://docs.stripe.com/api/idempotent_requests)
