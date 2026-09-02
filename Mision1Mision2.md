# Misión 1: El cuadro en tus propias palabras

| El problema en corto | Capa | Patrón que lo arregla | En mis palabras (y por qué no el otro) |
| :--- | :--- | :--- | :--- |
| 1. El mismo código de sesión pegado en 40 archivos. | Presentación (Filtros) | Intercepting Filter | Es como un cadenero. En vez de revisar el gafete en cada oficina, lo revisas en la entrada. Si no trae sesión, lo rebotas. Rechazamos Template porque no estamos haciendo una plantilla visual, estamos validando reglas antes de entrar. |
| 2. Un código de 200 líneas lleno de "IFs" para cobrar. | Aplicación | Strategy | Es como tener diferentes terminales de cobro. En vez de un código espagueti, haces una "caja" para SPEI y otra para Tarjeta. Usas la que ocupes sin romper las demás. Rechazamos State porque aquí el pago no cambia de estado, solo cambia la forma de cobrar. |
| 3. El banco usa códigos raros y nosotros no. | Integración | Adapter | Es literal un traductor. El banco nos manda códigos (00/01) y el adaptador los traduce a "Acreditado" para que nuestro sistema lo entienda fácil. Rechazamos Facade porque Facade resume pasos, pero Adapter traduce idiomas entre sistemas. |
| 4. Las consultas a la base de datos están revueltas en el diseño. | Datos | Repository | Es el archivero. Sacas todo el código SQL de la vista y lo metes aquí. Así el sistema solo dice "dame las calificaciones" sin ensuciarse. Rechazamos Active Record porque amarra mucho la base de datos al código, y aquí ocupamos consultas más flexibles. |
| 5. Si falla el correo, no se guarda el pago. | Aplicación / Eventos | Observer + Unit of Work | Unit of Work es "o se guarda todo limpio, o se cancela todo" (para no cobrar doble). Observer es como un grupo de WhatsApp: el sistema avisa "¡Ya pagó!" y el de los correos lo lee y lo manda a su ritmo, sin trabar la página. |
| 6. La app del celular hace 12 peticiones para abrir. | Presentación (API) | BFF (Backend for Frontend) | Es como pedir en combo. En vez de que el celular pida 12 cosas sueltas y se tarde mil años, armamos una ruta especial que le entregue todo en un solo paquete ligero. Rechazamos Facade porque BFF está hecho a la medida exacta de la app móvil. |

# Misión 2: El viaje del pago (paso a paso sencillo)

1. **La Recepcionista (Front Controller):** El alumno da clic en pagar. El sistema recibe esa petición en un solo lugar central y decide a qué parte del código mandarla.
2. **El de Seguridad (Intercepting Filter):** Antes de hacer cualquier cosa, un filtro revisa rápido si el alumno tiene su sesión activa. Si todo está bien, lo deja pasar.
3. **El que toma la orden (Controlador MVC / DTO):** Agarra los datos crudos que mandó el alumno (monto, tarjeta) y los empaqueta bonito para que la lógica de negocio los pueda procesar sin errores.
4. **La Caja Fuerte (Unit of Work):** Como vamos a tocar dinero y calificaciones, abrimos una transacción. Es nuestra garantía de que si el sistema se cae a la mitad, no le cobramos doble al alumno (hace rollback).
5. **La Terminal de Cobro (Strategy):** El sistema revisa con qué quiere pagar el alumno y saca la herramienta correcta (la clase de SPEI o la de Tarjeta).
6. **El Traductor (Adapter):** Nos comunicamos con el banco. Como el banco habla otro idioma técnico, el adaptador traduce su respuesta para avisarnos claramente si el pago pasó.
7. **El Archivero (Repository):** Ya que tenemos el dinero seguro, guardamos el registro en la base de datos de forma limpia, sin usar sentencias SQL directas.
8. **El Megáfono (Observer):** Ya quedó todo guardado. En lugar de hacer esperar al alumno viendo una ruedita de carga, el sistema grita internamente: "¡Pago exitoso!". El módulo de correos escucha eso y manda el recibo en segundo plano, mientras el alumno ya está viendo su pantalla de éxito.
