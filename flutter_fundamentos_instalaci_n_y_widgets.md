# Flutter: fundamentos, instalación y widgets

---

Análisis de los ejemplos de instalación, estado y widgets de los apuntes.

## Instalación

El ejemplo inicial crea un proyecto mediante `flutter create` y lo ejecuta en el navegador con `flutter run -d chrome`. El comportamiento predeterminado muestra la aplicación de demostración del contador, validando que la estructura de directorios y dependencias quedó establecida correctamente. El parámetro `-d chrome` le indica a Flutter que despliegue la interfaz directamente en la plataforma web.


---

## StatelessWidget

Es un widget sin un objeto `State` mutable propio. Puede reconstruirse cuando cambian la configuración recibida del padre o las dependencias del contexto; no está limitado a interfaces estáticas. El ejemplo recibe un identificador (folio) y lo muestra. El widget puede reconstruirse si su padre le entrega otro folio. Cambiar una variable externa por sí solo no notifica al framework; la recarga en caliente recompila cambios de código y conserva el estado cuando es posible.


---

## StatefulWidget

A diferencia del componente anterior, este modelo administra un estado interno mutable que dispara un re-renderizado gráfico cada vez que su valor se actualiza. Al interactuar con el botón **Sumar**, el contador incrementa de forma secuencial. Este ciclo depende del método `setState`, el cual notifica al framework que los datos cambiaron y que es necesario reconstruir la interfaz afectada. Omitir `setState` provocaría que la variable interna cambie de valor, pero no se solicitaría una reconstrucción por ese cambio; podría verse después si otro motivo provoca una reconstrucción.


---

## Widgets básicos

### Esqueleto de pantalla

La interfaz muestra una barra superior con el título **Entregas**, seguida de la etiqueta *Nuevo pedido*, un campo de entrada para la distancia y el botón de acción inferior **Crear pedido**. El campo de texto acepta caracteres alfanuméricos libremente, mientras que el botón permanece inactivo visualmente (`onPressed: null`) como parte de la configuración inicial del diseño. La estructura organiza los componentes de manera vertical dentro de un contenedor principal.


### Lista de pedidos

Se compone de una barra de navegación con el título **Pedidos** y un conjunto de filas repetitivas que muestran un icono de camión, un folio y la leyenda *tocar para ver detalle*. Cada elemento es interactivo; al seleccionarlo, la aplicación emite una notificación en la parte inferior indicando cuál registro específico fue seleccionado.


### Row + Expanded

El uso de `Expanded` dentro de una estructura `Row` permite distribuir el espacio disponible de manera eficiente: el hijo envuelto en `Expanded` ocupa el espacio restante y la etiqueta **dron** se desplaza automáticamente hacia el extremo derecho, evitando superposiciones de texto.


Al prescindir de `Expanded`, los textos se colocan de forma continua, provocando que los elementos excedan los límites de la pantalla si el contenido es muy largo o si la ventana se redimensiona. En el entorno web, este desbordamiento genera una advertencia gráfica de color amarillo con negro y un reporte detallado en la consola indicando la cantidad exacta de píxeles excedidos.


### Switch

Implementa un control de activación para el parámetro **Envío urgente**, acompañado de una transición animada al alternar su estado. El widget padre almacena el booleano y entrega `value` y `onChanged` al `Switch`. El callback actualiza ese estado mediante `setState` u otro mecanismo de gestión de estado.


### Dropdown

Funciona como un menú de selección desplegable que agrupa tres opciones de transporte: motocicleta, dron y camioneta. Su arquitectura separa el texto descriptivo visible para el usuario del valor interno asociado que se procesa en la lógica del sistema.


### AlertDialog

Al accionar el botón principal, se despliega una ventana modal superpuesta que solicita confirmación para procesar la petición, ofreciendo las alternativas **Cancelar** y **Sí**. `showDialog` devuelve un `Future` que puede esperarse con `await` sin bloquear la interfaz; si se confirma afirmativamente, se activa un aviso temporal de respuesta en la parte inferior de la pantalla.


### Navigator

Gestiona el flujo de navegación mediante una estructura de pila (`stack`). Al seleccionar un elemento de la lista principal, la vista de detalle se coloca en el nivel superior de la jerarquía, mostrando el identificador correspondiente y un control **Volver** que permite deshacer el cambio para regresar al listado anterior.


### CircularProgressIndicator

Representa un indicador gráfico de actividad asíncrona que se activa al interactuar con el botón de procesamiento. Durante la ejecución, el control bloquea la interacción y muestra un elemento de carga animado. Tras un intervalo simulado, el sistema oculta el indicador y actualiza la interfaz con el resultado final correspondiente.


---

## Preguntas cortas

> **1. ¿Qué problema de mantenimiento ataca Flutter al existir web y móvil en el mismo producto?**

Permite centralizar el código base en un solo repositorio. Esto reduce la duplicación de interfaz y lógica del cliente entre plataformas, aunque puede requerir ajustes específicos. Existen otras tecnologías multiplataforma, y las reglas de negocio del backend siguen siendo responsabilidad del servidor.

> **2. ¿Por qué Flutter dibuja sus propios controles en lugar de usar solo los nativos del sistema?**

Para garantizar consistencia visual y un rendimiento gráfico uniforme en cualquier dispositivo. Al renderizar directamente sobre el motor gráfico, la aplicación evita depender de las variaciones o limitaciones de los componentes nativos de cada sistema operativo.

> **3. ¿En qué se diferencian un `StatelessWidget` y un `StatefulWidget`?**

El primero no mantiene un objeto `State` mutable propio, pero puede reconstruirse al cambiar su configuración o sus dependencias. El segundo incorpora un ciclo de vida con gestión de estado interno, permitiendo redibujar sectores específicos de la pantalla de forma dinámica mediante la función `setState`.

> **4. Si `flutter doctor` marca un problema en Android pero Chrome funciona, ¿se puede empezar la clase de widgets igual? ¿Qué no se podría hacer todavía?**

Sí es posible avanzar con las prácticas utilizando la plataforma web como entorno de ejecución. La limitación principal radica en la imposibilidad de compilar binarios nativos (`.apk`) o desplegar la solución en emuladores y dispositivos físicos Android hasta completar la configuración de las herramientas de desarrollo correspondientes.

> **5. ¿Por qué un `Column` sin `Expanded` a veces «desborda» la pantalla cuando se meten muchos hijos?**

Porque un componente `Column` distribuye a sus elementos hijos tomando como referencia el espacio físico que cada uno demanda de forma intrínseca. Si la sumatoria vertical supera las dimensiones disponibles del contenedor padre, el excedente queda fuera del área visible de renderizado.

> **6. ¿Qué widget se usaría para mostrar muchos folios con scroll, y cuál para avisar «pedido creado» sin cambiar de pantalla?**

Para la visualización de colecciones extensas con capacidad de desplazamiento se emplea un `ListView` en conjunto con elementos `ListTile`. Para notificaciones rápidas de confirmación se utiliza un `SnackBar`, el cual despliega un mensaje flotante temporal en la sección inferior.

> **7. ¿En qué se parece el ejemplo de `CircularProgressIndicator` a una llamada real al gateway?**

Comparte la misma secuencia lógica de control asíncrono: se inicia un estado de espera activa mientras el sistema procesa la solicitud externa, y una vez obtenida la respuesta (simulada en este caso con un retraso temporal), la interfaz se actualiza para reflejar el resultado obtenido.

## Referencias técnicas

- [Estado local y estado de aplicación — Flutter](https://docs.flutter.dev/data-and-backend/state-mgmt/ephemeral-vs-app)
