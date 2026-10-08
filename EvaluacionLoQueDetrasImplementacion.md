# Actividad individual — Lo que hay detrás de la implementación

Nombre: Diego Rivera Cisneros

Matrícula: 22121364

## A1
Ana se equivoca porque Docker aísla todo el sistema operativo (es como tener otra compu adentro), pero el entorno virtual (venv) solo aísla las librerías de Python; usar ambos no sobra. Luis se equivoca porque `runserver` es solo para desarrollo, si entra mucha gente real al mismo tiempo, se va a trabar. El venv lo usamos para que no choquen las versiones de las librerías en nuestra compu, y el contenedor para que el proyecto corra exactamente igual en la compu de cualquiera sin importar si usa Windows o Mac.

## A2
a) No perdió su código. La carpeta `.venv` solo guarda los paquetes y librerías instaladas de internet, no sus archivos `.py`.
b) Solo necesita volver a crear el entorno (`python -m venv .venv`), activarlo e instalar las cosas con `pip install -r requirements.txt`. Ese archivo es como la lista del súper que le dice a Python qué bajar.
c) "Activar" no instala nada, solo le cambia el "chip" a la terminal para que use el Python de esa carpeta en vez del de la compu. Hay que repetirlo porque cada terminal que abres es independiente.

## A3
a) La carpeta `/app` solo existe adentro del contenedor de Docker, no en tu disco duro normal. El comando `COPY . .` copia todo lo que tienes en tu carpeta actual hacia esa carpeta `/app` dentro del contenedor.
b) Ignorar `.venv` evita que copiemos librerías que se compilaron para Windows/Mac y que no van a jalar en el Linux de Docker. Ignorar `db.sqlite3` evita que sobreescribamos la base de datos o subamos datos de prueba que no van a producción.

## B1
a) Que cuando hagan la app móvil van a tener que programar otra vez todas esas reglas desde cero. Y si un día cambian una regla, van a tener que actualizar el código de la web y el de la app por separado.
b) El frontend se puede cambiar fácil porque solo se encarga de los botoncitos y los colores. El backend es el cerebro y lo único que le entrega al frontend son puros datos en texto (como JSON).

## B2
La app de los teléfonos viejos va a tronar o dejar de mostrar las opciones porque va a buscar la palabra "medios_disponibles" y ya no la va a encontrar. El "contrato" es el acuerdo de qué datos exactos se van a mandar y cómo se llaman. El campo version sirve para sacar una versión 2.0 con el nombre corto, sin borrar la 1.0 para que las apps viejas sigan jalando.

## B3
No estoy de acuerdo. La validación del frontend es solo para que el usuario tenga una experiencia rápida y no recargue la página si se equivoca, pero el backend TIENE que validar siempre. Si quitamos la del backend, alguien podría saltarse la página web (usando Postman por ejemplo) y meter datos basura directo a la base.

## C1
a) Escalar verticalmente es ponerle más RAM y un mejor procesador a la misma compu (hacerla más potente). Escalar horizontalmente es poner más computadoras normales a trabajar en equipo.
b) El límite del vertical es que llega un punto donde las piezas son carísimas o físicamente ya no existen computadoras más potentes.
c) Funciona como un cadenero repartiendo gente: le manda una petición a la copia 1, la siguiente a la 2, la otra a la 3 para que no se sature ninguna.

## C2
a) Porque el diccionario vive en la memoria RAM. Como son 3 copias diferentes, cada una tiene su propia RAM aislada; la copia 2 no tiene idea de lo que la copia 1 guardó.
b) Porque cada copia usa Gunicorn con 2 workers (sub-procesos). La petición que guardó el dato cayó en el worker A, pero la petición que lo fue a buscar cayó en el worker B de esa misma copia.
c) No, Docker no rompió nada. El código ya estaba mal desde el inicio porque dependía de guardar cosas temporales en la memoria local en vez de usar una base de datos.

## C3
Falla por lo mismo: una variable global solo vive en la memoria de un solo worker. La sesión sí funciona porque Django guarda `request.session` directamente en la base de datos, así que sin importar qué copia o worker te atienda en el paso dos, todos van a leer de la misma base.

## C4
a) Los clientes recibirían el mismo correo 5 veces (uno por cada copia). Esas tareas programadas no deben vivir en la app web, sino en un proceso aparte que solo corra una vez.
b) Porque si las 5 copias intentan modificar la base de datos al mismo tiempo al prender, pueden chocar y corromper todo. Migrar se hace una sola vez antes de levantar las copias.
c) Abrirían 80 conexiones al mismo tiempo. Si agregamos copias "sin límite", vamos a saturar a PostgreSQL y se va a caer por exceso de conexiones. SQLite no sirve porque se bloquea si varios intentan escribir al mismo tiempo.

## D1
a) No dice nada porque la IA hizo "trampa" memorizando las respuestas. Es como si te aplican el mismo examen que usaste para estudiar.
b) Para hacerle un examen real con datos que nunca ha visto y comprobar si de verdad entendió los patrones o si solo memorizó.
c) Evita que, por mala suerte, los poquitos ejemplos de dron se queden todos en el entrenamiento o todos en la prueba. Garantiza que la proporción se mantenga en los dos lados.

## D2
Le daría a entender al árbol que hay un orden matemático (como que "viento fuerte" vale el doble que "lluvia"). El one-hot encoding lo evita creando columnas de Sí/No para cada clima.
El Pipeline se guarda junto para asegurar que, el día de mañana, cualquier paquete nuevo sufra exactamente las mismas transformaciones antes de entrar al modelo, evitando errores.

## D3
a) Porque hizo overfitting (sobreajuste). El árbol creció tanto que se aprendió de memoria hasta los casos raros (ruido) del entrenamiento, por lo que le va peor cuando ve datos nuevos.
b) Elegimos 8 porque la diferencia de exactitud es mínima, pero un árbol de nivel 8 es mucho más sencillo, rápido y menos propenso a fallar a futuro que uno de 10.

## D4
a) Precision: de todas las veces que la IA dijo "va en dron", el 83.9% de las veces tenía razón. Recall: de todos los paquetes que SÍ debían ir en dron en la vida real, la IA logró identificar al 90.5%.
b) Es peor mandar en dron algo que no debía (puede ser muy pesado y se cae). Ese error (falso positivo) lo mide la Precision.
c) Porque la vida real no es perfecta y hay datos atípicos. No es malo, significa que el modelo entendió las reglas generales sin obsesionarse con memorizar todo (no hizo overfitting).

## D5
Le diría que no se fije solo en el 1% extra de exactitud. Primero, el Random Forest pesa 60MB (va a consumir más RAM y ser más lento que el de 14KB). Segundo, es una "caja negra"; si un paquete importante se va mal, con el árbol podemos leer la regla y saber por qué falló, con el bosque no.
En la vista de Django no cambia casi nada, a lo mucho importaríamos el nuevo archivo, porque gracias al diseño orientado a objetos usamos la IA a través de una interfaz estandarizada.

## E1
a) Porque en el historial (entrenamiento) seguro casi no había registros de drones volando a las 3 am, así que la IA no sabe qué hacer y predice a ciegas.
b) Porque la IA se basa en estadística y siempre puede fallar. Las reglas de negocio son leyes estrictas de la empresa (ej. "los drones no vuelan de noche") que no pueden depender de si la IA tiene el 99% o el 10% de confianza.
c) Porque es mejor tener las responsabilidades separadas. Si mañana el gobierno cambia el horario de vuelo de drones, solo modificamos el archivo de reglas sin tener que re-entrenar toda la IA.

## E2
No es contradicción. El modelo es un archivo pesado, de solo lectura, que todos usan igual; cargarlo a RAM una vez hace que todo sea rapidísimo. Un pedido es un dato dinámico de un usuario específico. Si cada petición cargara el archivo `.joblib` desde cero, la página tardaría segundos en responder y se saturaría el disco duro.

## E3
Pasa porque no le pusieron la versión exacta. Al construir el Docker meses después, bajó la versión más nueva de scikit-learn y resultó ser incompatible con el modelo viejo. Se evita escribiendo las versiones exactas (ej. `scikit-learn==1.9.0`). Tiene todo que ver con la idea del entorno virtual y Docker: la meta es que el entorno sea *idéntico*, y sin versiones exactas, eso es imposible.

## F1
a) Solo hay que crear una nueva clase (ej. `RecomendadorIAExterna`) que use la misma interfaz que usaba `RecomendadorIA`. Este es el patrón Strategy (o Adapter). La fábrica, la vista y las estrategias de los vehículos quedan intactas.
b) La IA solo toma la decisión de qué vehículo usar (el string "DRONE"). El diseño (la plataforma) sigue haciendo todo lo demás: recibir la petición, validar los datos, aplicar reglas de negocio para ver si la IA no dijo una tontería, crear el objeto de entrega y formatear la respuesta.
c) 1. Si el servicio de IA se cae, con el patrón Strategy podemos volver a enchufar nuestro árbol de decisión local en un segundo sin reescribir toda la aplicación. 2. La IA solo nos da una palabra, pero necesitamos los patrones (como Factory) para que el sistema construya el objeto real (`EntregaDron` o `EntregaMoto`) que tiene la lógica de cómo se hace el envío físico.
