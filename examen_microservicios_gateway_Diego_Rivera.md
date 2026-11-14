━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               EXAMEN — MICROSERVICIOS, GATEWAY Y EL MONOLITO
                                    CON API
             Tópicos Selectos de Tecnologías Web y Móvil

                         Eduardo Alcaraz
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Nombre: Diego Rivera Cisneros                      Calificación: _________


Indicaciones
════════════

  Este examen *no* se aprueba de memoria. Casi todas las preguntas
  tienen una respuesta que «suena bien» y está mal, o dos opciones
  defendibles donde se califica el argumento.

  Reglas:

  • Expliquen el *porqué*. Una conclusión sin razonamiento vale la mitad
    (o menos).
  • Cuando digan «depende», digan *de qué*.
  • No hace falta código que compile; sí hace falta que el diseño cierre
    (quién llama a quién, qué pasa si algo falla, qué ve el cliente).
  • Pueden dibujar. Un dibujo contradictorio con el texto resta.

  Puntaje: *100 puntos* (10 × 10).


1 — La frase del compañero (10 puntos)
══════════════════════════════════════

  En el pizarrón quedó:

        La API separa clientes del servidor; los microservicios
        separan servidores entre sí.

  Un compañero dice: «Entonces, si mi monolito Django expone una API y
  además lo meto en Docker, ya cumplí las duas mitades de la frase.»

  a) Desarmen su argumento. ¿Qué parte de la frase cree cumplir con la
  API? ¿Qué parte cree cumplir con Docker? ¿En qué se equivoca en cada
  una?
En cuanto a la API, acierta parcialmente porque expone endpoints con DRF, pero se equivoca al justificar Docker. Contenerizar con Docker solo encapsula un proceso; un contenedor que encierra toda la aplicación de Django sigue siendo exactamente un monolito: una unidad de despliegue que agrupa esas responsabilidades. Puede tener varios procesos o réplicas; eso no cambia por sí solo su arquitectura monolítica.

  b) Den un contraejemplo mínimo: mismo código Django, *con* API y *con*
  Docker, que *sigamos* pudiendo llamar monolito. ¿Qué tendría que
  añadir (o partir) para que deje de serlo?
Un proyecto Django clásico que maneje en el mismo código las apps de usuarios, pedidos y recomendaciones, expuestas mediante Django REST Framework, empaquetado en un único `Dockerfile`, corriendo en un contenedor individual y conectado a una sola base de datos. Tiene API y tiene Docker, pero sigue siendo un monolito. Dejará de serlo en el momento exacto en que dividas físicamente el código en procesos independientes con ciclos de vida y despliegues separados. Cada servicio debe poder desplegarse de forma independiente, con contratos definidos y responsabilidad sobre sus datos. Usar imágenes distintas ayuda a expresarlo, pero no es un requisito universal de los microservicios.

  c) ¿La frase del pizarrón habla de *tecnologías* (Docker, REST) o de
  *límites de proceso / despliegue*? Defiendan su lectura con lo que
  vieron en clase.
La frase hace referencia estricta a los límites lógicos de proceso y a las unidades de despliegue, no a herramientas tecnológicas específicas. En las sesiones de clase analizamos que los microservicios constituyen un patrón de arquitectura y diseño organizacional. La prueba tangible es operativa: si puedo apagar o actualizar el servicio de recomendaciones de manera totalmente independiente sin afectar ni requerir un nuevo despliegue del módulo de pedidos, estamos hablando de una separación real; de lo contrario, por más herramientas modernas que usemos, la separación no existe.


2 — Tres rutas, una trampa (10 puntos)
══════════════════════════════════════

  El equipo muestra este `urls.py' de un solo proyecto Django:

  ┌────
  │ path("usuarios/", ...),
  │ path("pedidos/", ...),
  │ path("recomendar/", ...),
  └────

  y este `docker-compose.yml':

  ┌────
  │ services:
  │   api:
  │     build: .
  │     ports: ["8000:8000"]
  │     deploy:
  │       replicas: 3
  └────

  Afirman: «Tres rutas + tres réplicas = microservicios con alta
  disponibilidad.»

  a) Separen las dos ideas que mezclaron (rutas vs réplicas). ¿Qué
  problema resuelve cada una y cuál *no* resuelve?
Por un lado, las rutas definidas en el enrutador simplemente organizan lógicamente el código dentro del mismo proceso de software; aportan orden estructural, pero cero independencia, ya que si recomendaciones agota los recursos compartidos o provoca una caída del proceso, puede afectar a los demás módulos; un error controlado no necesariamente derriba toda la aplicación. Por otro lado, las réplicas generan copias idénticas de ese mismo monolito base; esto último sí aporta alta disponibilidad y capacidad de expansión ante carga, pero jamás soluciona el acoplamiento de responsabilidades. Además, intentar levantar tres réplicas exponiendo idénticamente el puerto fijo `8000:8000` sin un balanceador de carga previo generará un conflicto inminente de puertos.

  b) Si una de las tres réplicas se cae a mitad de un `POST /pedidos',
  ¿el sistema dejó de ser monolito? ¿Por qué sí o por qué no?
El sistema no pierde su naturaleza de monolito por el simple hecho de que una instancia falle, ya que la definición de arquitectura monolítica depende de la unidad de despliegue y del acoplamiento del código, no de la salud transitoria de sus contenedores. Lo que ocurre operativamente es que la petición en curso se interrumpe, el cliente percibe un error de red y, si reintenta enviar la solicitud sin un identificador de idempotencia o folio previo, se arriesga a duplicar por completo el registro del pedido.

  c) Rediseñen *solo con palabras* el `compose' para que sí ilustre
  microservicios (nombres de servicios y responsabilidades; no hace
  falta YAML perfecto). ¿Cuántas *imágenes distintas* mínimo y por qué
  esa cantidad?
- Gateway: encargado exclusivamente de la entrada perimetral, validación de credenciales JWT y redirección de tráfico.
- Usuarios: servicio con su propio espacio de datos exclusivo.
- Pedidos: módulo de transacciones con su base de datos propia y comunicación hacia recomendaciones.
- Recomendar: servicio analítico dedicado a procesar los modelos predictivos mediante archivos serializados.
Para esta propuesta se usarían 3 imágenes de desarrollo propio (usuarios, pedidos y recomendador), puesto que cada una encapsula un código fuente independiente y se despliega por separado; sumando el contenedor perimetral con la imagen oficial de Nginx, el total operativo es de 4 servicios. La independencia se verifica por los despliegues y contratos, no por contar imágenes: una misma imagen podría ejecutar servicios distintos con comandos separados.


3 — El gateway que «hace de más» (10 puntos)
═══════════════════════════════════════════════

  Les proponen este diseño «para no complicar»:

        Un solo contenedor nginx+Python que: valida el JWT, elige
        el medio con el `.joblib', guarda el pedido en SQLite,
        manda el correo y devuelve el HTML.

  Lo llaman «API Gateway».

  a) ¿Es un gateway? Si no, ¿qué es? Usen la analogía del recepcionista
  (o otra) y digan qué oficios mezclaron.
Definitivamente no es un gateway; se trata de un monolito envuelto con un servidor Nginx al frente. Usando la analogía de un edificio corporativo, un verdadero gateway actúa como el vigilante de la entrada: filtra quién pasa, verifica credenciales y distribuye hacia los departamentos correctos sin involucrarse en las tareas internas. En este mal diseño, el vigilante de la puerta además calcula la logística de envíos, escribe en los libros contables de la base de datos y se pone a repartir la correspondencia postal. Mezclaron el control perimetral, la lógica de negocio pesada, la persistencia de datos y la mensajería asíncrona en una sola entidad.

  b) Mencionen *tres* consecuencias malas de ese diseño cuando el modelo
  pesado se reentrena cada semana y el correo empieza a fallar.
1. Cada ciclo semanal de reentrenamiento y actualización del archivo `.joblib` obliga a redesplegar toda la aplicación completa, provocando interrupciones incluso en los flujos de autenticación y login de los usuarios.
2. Si el servicio externo de correo electrónico experimenta fallas de conectividad, el proceso completo de registro del pedido se bloquea y se reporta como fallido, invitando al cliente a reintentar y duplicar transacciones.
3. El motor de inferencia analítica consume recursos intensivos de CPU y memoria RAM que compiten directamente con las validaciones de seguridad del JWT, mientras que SQLite limita las escrituras concurrentes y exige planificar la persistencia. Un reinicio no implica corrupción; al eliminar o recrear un contenedor sin almacenamiento persistente sí pueden perderse los datos de su capa escribible.

  c) Partan ese contenedor en piezas. Para cada pieza digan: ¿queda en
  el borde (gateway) o detrás? No inventen diez servicios: el mínimo que
  separe borde, logística e (si hace falta) aviso.
- Borde (Gateway perimetral): encargado de la validación de tokens JWT, control de tasa de peticiones (rate limiting), entrega de plantillas HTML y ruteo inteligente.
- Detrás de la red interna: microservicio de Pedidos, microservicio de Recomendaciones y un componente desacoplado de Avisos (operando de forma asíncrona mediante colas).


4 — `localhost', la trampa favorita (10 puntos)
═══════════════════════════════════════════════

  Pedidos corre en un contenedor. Recomendar en otro, misma Compose.
  Alguien «arregla» la conexión así:

  ┌────
  │ RECOMENDAR_URL=http://127.0.0.1:8002
  └────

  En su laptop, *sin* Docker, ese `curl' a `127.0.0.1:8002' sí
  funcionaba.

  a) Expliquen por qué en Compose ese arreglo suele fallar *aunque*
  Recomendar esté sano. ¿A qué proceso apunta `127.0.0.1' desde dentro
  de Pedidos?
Cada contenedor Docker opera dentro de su propio espacio de red aislado. Por lo tanto, al interior del contenedor de Pedidos, la dirección `127.0.0.1` apunta exclusivamente a su propio loopback interno, donde no se encuentra escuchando ningún proceso en el puerto `8002`. Como resultado, la petición se rechaza de inmediato, independientemente de que el contenedor de recomendaciones esté completamente saludable en otra parte del entorno.

  b) Por qué `http://recomendar:8002' sí tiene chance de funcionar?
  ¿Quién «inventa» el nombre `recomendar'?
Funciona correctamente porque Docker Compose configura de manera automática una red privada virtual interna dotada de un servidor DNS integrado que traduce los nombres de los servicios configurados. El nombre clave `recomendar` surge directamente del identificador que asignamos bajo la directiva `services:` dentro del archivo `docker-compose.yml`, y el puerto especificado debe coincidir exactamente con el puerto expuesto de escucha interna del contenedor destino.

  c) Ahora Recomendar se muda a la laptop de otro alumno
  (`192.168.0.57'). Escriban la URL que pondrían *y* dos cosas que
  tienen que ser verdad en la WiFi para que no sea teatro (puertos,
  firewall, etc.). Si solo cambian la URL y nada más, qué puede seguir
  fallando?
La URL correcta a configurar sería `http://192.168.0.57:8002`.
Para que la comunicación prospere, es indispensable que:
1. El servicio de recomendaciones en la máquina de destino esté escuchando activamente en todas las interfaces de red (`0.0.0.0`) y no confinado únicamente al loopback local (`127.0.0.1`), manteniendo el puerto `8002` abierto y accesible.
2. El software de contención o firewall del sistema operativo de esa laptop permita el tráfico entrante por dicho puerto, y que la red Wi-Fi utilizada no tenga activadas políticas de aislamiento entre clientes (AP Isolation).
Si únicamente se modifica la variable de URL sin verificar estos requisitos, la aplicación sufrirá constantes tiempos de espera por expiración (`timeout`), con el riesgo latente de que los mecanismos de contingencia actúen silenciosamente, haciendo creer que todo opera con normalidad cuando en realidad el motor analítico externo jamás fue consultado.


5 — Fallo parcial con números (10 puntos)
═════════════════════════════════════════

  Escenario medido en laboratorio (inventado pero coherente):

  • 1000 `POST /pedidos' por hora en promedio.
  • Recomendar tarda 200 ms cuando está bien.
  • El 5 % del tiempo Recomendar no responde (timeout 3 s).
  • Pedidos, si hay timeout, usa plan B (moto) y responde 200 en 50 ms.
  • El gateway añade 5 ms.

  a) En la hora «normal» (Recomendar bien), ¿el cliente espera ~200 ms o
  ~3 s? ¿Quién pone el tiempo dominante?
El tiempo de espera percibido por el cliente se sitúa en aproximadamente 205 milisegundos (200 ms de procesamiento del servicio de recomendaciones más los 5 ms añadidos por la capa perimetral del gateway). El componente que dicta el ritmo dominante de respuesta es el microservicio de recomendaciones.

  b) En el 5 % malo, con plan B: ¿el cliente ve error o pedido creado?
  ¿Qué «mentira útil» están aceptando (medio quizá no óptimo)?
El usuario final visualiza el pedido confirmado exitosamente con un código de respuesta HTTP 200, pero experimenta una latencia prolongada de aproximadamente 3.05 segundos debido a la espera necesaria para agotar el tiempo límite de conexión (`timeout`) antes de activar la alternativa de respaldo en moto. La «mentira útil» consiste en aceptar un medio de transporte predeterminado que quizá no sea el óptimo ni el más eficiente para ese envío en particular, a cambio de garantizar la continuidad de la transacción y evitar la pérdida del cliente. Este escenario desfrecuente eleva la latencia media global del sistema a cerca de 348 milisegundos.

  c) Un compañero dice: «Mejor que Pedidos *reintente* 10 veces hasta
  que Recomendar vuelva; así nunca usamos plan B.» ¿Qué le pasa a la
  cola de peticiones y al gateway si Recomendar está caído 10 minutos?
  ¿Plan B siempre es peor que reintentar? Argumenten.
Si se implementa una política de reintentos masivos y ciegos (por ejemplo, 10 intentos consecutivos con esperas de 3 segundos), cada petición fallida retendría recursos operativos durante unos 30 segundos. Ante un flujo constante durante 10 minutos, se retendrían recursos y aumentaría la concurrencia. Con 1,000 solicitudes/hora y 30 segundos por solicitud, habría unas 8.3 solicitudes simultáneas en promedio bajo un flujo uniforme; la saturación y los errores `504` dependerían de los límites de recursos, las ráfagas y el timeout del gateway. Cuando el servicio de recomendaciones finalmente se recupere, recibirá una avalancha repentina de peticiones acumuladas que podría volver a colapsarlo. Por otro lado, el plan B no es universalmente peor; si un envío por un medio inadecuado implica altos costos económicos o riesgos operativos graves, resulta preferible marcar la transacción como pendiente de revisión en lugar de forzar una ejecución errónea.


6 — Apagan el «edificio equivocado» (10 puntos)
═══════════════════════════════════════════════

  Tres contenedores: gateway, pedidos, recomendar. Hacen tres
  experimentos *por separado*:

  1. `docker compose stop gateway'
  2. `docker compose stop pedidos'
  3. `docker compose stop recomendar'

  Para *cada* experimento digan qué ve el navegador en `http://IP:8080/'
  (página / crear pedido) y qué sigue vivo por dentro. No basta «no
  jala»: digan *qué* no jala y qué sí podría seguir respondiendo si
  alguien hablara por dentro de la red.

  Luego: ¿en cuál de los tres el sistema «parece» más muerto hacia
  afuera aunque más piezas sigan arriba? ¿Qué les enseña eso del borde?
1. Al detener el gateway, el navegador es incapaz de establecer conexión, por lo que no carga ninguna interfaz gráfica ni procesa solicitudes; sin embargo, en la red interna los contenedores de pedidos y recomendaciones permanecen completamente operativos y listos para procesar llamadas internas si existieran.
2. Al detener el servicio de pedidos, la interfaz web principal provista por el gateway sigue cargando con normalidad, pero al intentar ejecutar la acción de crear un pedido la plataforma arroja un error de comunicación perimetral (`502 Bad Gateway`), mientras que el servicio de recomendaciones continúa activo pero inutilizado.
3. Al detener únicamente el recomendador, la interfaz carga sin inconvenientes y los pedidos pueden completarse con el plan B. Si la conexión se rechaza, el fallo puede detectarse rápido; si se descartan paquetes o la red no responde, habrá que esperar al timeout. Detener el contenedor no garantiza una respuesta inmediata.

El escenario donde la aplicación aparenta estar totalmente colapsada hacia el exterior a pesar de mantener la mayoría de sus componentes internos intactos es cuando se apaga el gateway (experimento 1). Esto nos demuestra de forma categórica que el borde perimetral constituye el punto único de fallo crítico de cara al usuario, por lo que debe mantenerse robusto, simplificado y dotado de mecanismos confiables de respaldo.


7 — WiFi del salón, conflicto de roles (10 puntos)
══════════════════════════════════════════════════

  Cuatro alumnos:

  • Ana: gateway + HTML
  • Beto: pedidos
  • Carla: recomendar
  • Diana: «yo también levanté un gateway en mi laptop por si Ana falla»

  Todos en la misma WiFi. El cliente (otro equipo) configura a veces la
  IP de Ana y a veces la de Diana.

  a) Qué problema de *diseño* introdujo Diana aunque «todo responda
  200»? (Piensen en una sola puerta vs dos puertas.)
Diana provocó una duplicación de accesos perimetrales («dos puertas distintas»), lo cual fragmenta drásticamente la consistencia operativa: las políticas de seguridad, autenticación, límites de tráfico y auditoría de registros (`logs`) pueden divergir entre ambos portales, obligando al cliente externo a adivinar de manera arbitraria a qué dirección apuntar. Contar con redundancia perimetral es una buena práctica, pero debe estructurarse detrás de una dirección unificada o un balanceador de carga, nunca exponiendo puntos de entrada independientes que confundan al sistema.

  b) Beto configuró `RECOMENDAR_URL=http://localhost:8002' porque en su
  máquina desarrolló Pedidos y Recomendar juntos. En el salón Recomendar
  está en la laptop de Carla. ¿Qué falla y cómo lo corrigen *sin* juntar
  otra vez los dos servicios en la laptop de Beto?
La configuración apunta al loopback local (`localhost`) de la máquina de Beto, donde el servicio analítico no existe, derivando todas las operaciones hacia el plan de contingencia. Se soluciona manteniendo intacto el código fuente y modificando exclusivamente la variable de entorno para apuntar a la dirección correcta: `RECOMENDAR_URL=http://<IP_de_Carla>:8002`, asegurando simultáneamente que el equipo de Carla permita conexiones externas y tenga el puerto abierto.

  c) La WiFi del campus aísla clientes («AP isolation»). `ping' entre
  alumnos falla. ¿Pueden hacer la práctica tal cual? Si no, propongan
  *un* plan B de laboratorio que preserve la lección «procesos
  separados» (aunque no sea WiFi del salón).
Bajo políticas estrictas de aislamiento de clientes en la red inalámbrica institucional, la comunicación directa entre los equipos de los alumnos resulta imposible. Como alternativa viable de laboratorio (Plan B), podemos conectar todas las computadoras participantes a una red inalámbrica privada compartida generada mediante el punto de acceso móvil (`hotspot`) de un teléfono celular o un enrutador portátil local sin restricciones de aislamiento. De esta forma, cada máquina mantiene su propia dirección IP en una red común, preservando fielmente el principio arquitectónico de procesos y despliegues distribuidos en equipos separados.


8 — El front que conoce demasiado (10 puntos)
═════════════════════════════════════════════

  El HTML hace esto al enviar el formulario:

  ┌────
  │ await fetch("http://192.168.1.20:8002/sugerir", { ... }); // Recomendar
  │ await fetch("http://192.168.1.30:8001/pedidos", { ... }); // Pedidos
  └────

  El autor dice: «Más rápido: me salto el gateway.»

  a) Listen *tres* problemas (seguridad, cambio de IP, orden de
  llamadas, consistencia del folio, CORS, etc.).
1. Se exponen direcciones IP internas y rutas de microservicios directamente en el cliente web, permitiendo que cualquier usuario externo invoque los servicios analíticos o transaccionales sin pasar por filtros de autenticación.
2. Si cualquiera de las direcciones IP de los servidores cambia en la red local, se rompe el funcionamiento del sistema y se obliga a realizar una actualización manual y masiva del código JavaScript en el navegador de todos los clientes.
3. Se rompe la consistencia transaccional: si la segunda llamada falla, la recomendación queda flotando de forma huérfana, además de generar múltiples conflictos de seguridad entre orígenes cruzados (políticas CORS) al intentar contactar servidores dispersos.

  b) Rediseñen la secuencia correcta con gateway: *una* llamada desde el
   navegador. ¿Quién habla con Recomendar y por qué no el navegador?
El navegador del cliente debe realizar una única petición HTTP centralizada de tipo `POST /api/pedidos` dirigida exclusivamente hacia el gateway perimetral. El gateway reenvía la solicitud al microservicio de pedidos, y es este último componente backend el encargado de comunicarse de forma interna y segura con el servicio de recomendaciones. El navegador jamás debe hablar directamente con componentes internos porque la lógica de negocio y la selección de modelos analíticos pertenecen estrictamente al servidor, protegiendo la integridad y desacoplando al cliente de la topología interna.

  c) El selector de modelo (`arbol=|=bosque=|=red') va en el JSON. Si el
  front llama directo a Recomendar *y* a Pedidos, qué debería crear
  el folio para no duplicar lógica? Qué invariante rompen si los dos
  «crean» algo?
La asignación y generación del folio transaccional corresponde de forma exclusiva al microservicio de pedidos; el recomendador funciona como un componente auxiliar que recibe parámetros y devuelve una sugerencia analítica sin persistir estados de negocio. Si ambos servicios intentaran generar identificadores o registros de forma descentralizada, se rompería la invariante fundamental de unicidad transaccional («un pedido válido equivale a un único folio con el medio definitivo calculado por el servidor»), generando colisiones de datos y registros duplicados inconsistentes.


9 — El LLM vendedor (10 puntos)
═══════════════════════════════

  Producto: tienda + envíos.

  • Modelo `.joblib': medio de transporte.
  • LLM: texto para convencer al cliente en la ficha del producto.

  Un arquitecto propone *un solo* microservicio `cerebro' que: recibe el
  carrito, elige el medio con el árbol *y* genera el pitch de ventas con
  el LLM, todo en la misma petición `/inteligente'.

  a) Critiquen el nombre y el corte. ¿Qué dos oficios distintos
  mezclaron? ¿Qué falla cuando el LLM tarda 8 s y el despacho necesita
  responder en < 500 ms?
El término «cerebro» carece de sentido de negocio y describe vagamente una tecnología en lugar de una responsabilidad funcional. En este diseño se mezclaron dos dominios completamente dispares: la lógica determinista de logística y despacho (un cálculo rápido y crítico para la operación) con las capacidades creativas de generación de lenguaje natural mediante un LLM (un proceso altamente costoso, lento y no crítico). Si el modelo de lenguaje sufre retrasos de hasta 8 segundos en responder, se incumple catastróficamente la restricción de latencia máxima de 500 milisegundos requerida para el despacho de pedidos, provocando además que una falla en el módulo de marketing tire por completo la operación logística.

  b) Propongan dos endpoints (o dos servicios) y digan cuál usa el
  *front de tienda* y cuál el *flujo de pedido/envío*.
- `/logistica/medio`: endpoint rápido y determinista utilizado exclusivamente por el flujo transaccional interno de pedidos y envíos.
- `/ventas/pitch`: endpoint analítico orientado al front-end de la tienda para la presentación de productos, soportado por estrategias de almacenamiento en caché y textos de respaldo genéricos en caso de fallos.

  c) El LLM vive en un server con GPU en otra red. El front de tienda
  ¿apunta a la GPU o al gateway? Si mañana cambian de proveedor LLM
  (otro host), qué archivo/config quieren tocar *una sola vez*?
El front-end de la tienda debe apuntar exclusivamente al gateway perimetral, jamás de forma directa a la infraestructura de servidores con GPU. Si en el futuro se decide migrar hacia un proveedor externo diferente de modelos de lenguaje, el único cambio necesario se reduce a actualizar la variable de configuración `LLM_URL` en el archivo de entorno del servicio correspondiente, permitiendo que la modificación ocurra en un solo punto sin requerir ninguna alteración en la interfaz de usuario.


10 — El inversionista y la semana imposible (10 puntos)
═══════════════════════════════════════════════════════

  Hoy:

  • Panel interno: monolito Django (funciona, poco tráfico).
  • App clientes: gateway + pedidos + recomendar.
  • Idea: LLM de ventas (aún no).
  • Equipo: 5 personas.
  • Inversionista: «Todo a microservicios en 7 días, incluido el panel,
    o no hay dinero.»

  a) Escriban la respuesta al inversionista (máx. 8 líneas) con postura
  *y* riesgo concreto si obedecen a ciegas.
Apoyamos la evolución a microservicios donde realmente aporte valor. La app de clientes ya está separada, pero fragmentar el panel funcional actual en solo 7 días con un equipo de 5 personas compromete la estabilidad del negocio. El riesgo operativo es que una migración apresurada e inmadura colapse el módulo de pedidos en producción y destruyamos la confianza de nuestros usuarios. Proponemos enfocar esta semana a blindar el gateway perimetral y aislar el reentrenamiento analítico, evaluando la partición del panel conforme el tráfico real lo justifique.

  b) Ordenen *estas cuatro* iniciativas de más a menos urgente para
  *esta* semana y justifiquen el orden (no el catálogo soñado):

  1. Partir el panel Django en 6 microservicios.
  2. Sacar el reentrenamiento del `.joblib' a un pipeline que no tumbe
     Pedidos.
  3. Meter auth + rate limit en el gateway público.
  4. Subir el LLM de ventas a producción sin timeouts ni plan B.
1. Implementar autenticación y límites de tráfico (`rate limiting`) en el gateway público (Prioridad 3), ya que la aplicación ya se encuentra expuesta al exterior y es una mejora rápida y de bajo costo.
2. Extraer el proceso de reentrenamiento del modelo predictivo hacia un pipeline independiente (Prioridad 2), puesto que hoy en día interrumpe y colapsa el servicio de pedidos cada semana.
3. Evaluar la integración del LLM de ventas bajo estrictas políticas de tiempo límite y planes de contingencia (Prioridad 4), descartando su despliegue directo sin protecciones.
4. Partir el panel monolítico de administración en múltiples microservicios (Prioridad 1), ya que funciona de manera estable y soporta un volumen de tráfico reducido, por lo que no representa una urgencia arquitectónica actual.

  c) Inventen *una* métrica que les diga «ya toca partir X del monolito»
  (no «porque está de moda»). Tiene que ser observable (tiempo, errores,
  despliegues, equipo…).
El porcentaje mensual de despliegues del monolito general que resultan bloqueados, retrasados o revertidos a causa de modificaciones específicas concentradas dentro del módulo en cuestión. Si más del 30 % de las modificaciones de dicho módulo interfieren negativamente con el ciclo de entrega global durante un mes consecutivo, el indicador justifica formalmente la extracción y separación de ese componente.

  d) Cierren con una frase propia (no copien el apunte) que capture:
  ¿microservicios son el objetivo o la herramienta?
Los microservicios nunca deben considerarse una meta en sí misma; son simplemente una herramienta especializada de diseño que se despliega únicamente cuando los límites y la complejidad del negocio exigen romper un monolito para evitar que el crecimiento nos ahogue.