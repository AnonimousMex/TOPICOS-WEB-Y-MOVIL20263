# Flutter: fundamentos, instalación y widgets

---

## Instalación

Se configuró el entorno inicial creando un nuevo proyecto mediante `flutter create` y ejecutándolo en el navegador con `flutter run -d chrome`. El comportamiento predeterminado muestra la aplicación de demostración del contador, validando que la estructura de directorios y dependencias quedó establecida correctamente. El parámetro `-d chrome` le indica a Flutter que despliegue la interfaz directamente en la plataforma web.

![Contador de demo en Chrome](img/contador-demo.png)

---

## StatelessWidget

Corresponde a un componente estático que renderiza exclusivamente la información recibida a través de sus propiedades, sin gestionar estados internos modificables. Durante la prueba en Chrome, el componente recibió un identificador (folio) y lo proyectó en pantalla. Al modificar directamente la variable externa, el componente no reflejó el cambio de manera automática hasta ejecutar la recarga en caliente (`hot reload`) presionando `r` en la terminal, lo que refresca el árbol de elementos sin perder la sesión activa.

![Folio mostrado en Chrome](img/stateless-folio.png)

---

## StatefulWidget

A diferencia del componente anterior, este modelo administra un estado interno mutable que dispara un re-renderizado gráfico cada vez que su valor se actualiza. Al interactuar con el botón **Sumar**, el contador incrementa de forma secuencial. Este ciclo depende del método `setState`, el cual notifica al framework que los datos cambiaron y que es necesario reconstruir la interfaz afectada. Omitir `setState` provocaría que la variable interna cambie de valor, pero el cambio visual jamás se reflejaría en la pantalla.

![Contador con el botón Sumar](img/stateful-contador.png)

---

## Widgets básicos

### Esqueleto de pantalla

La interfaz muestra una barra superior con el título **Entregas**, seguida de la etiqueta *Nuevo pedido*, un campo de entrada para la distancia y el botón de acción inferior **Crear pedido**. El campo de texto acepta caracteres alfanuméricos libremente, mientras que el botón permanece inactivo visualmente (`onPressed: null`) como parte de la configuración inicial del diseño. La estructura organiza los componentes de manera vertical dentro de un contenedor principal.

![Esqueleto de pantalla](img/esqueleto.png)

### Lista de pedidos

Se compone de una barra de navegación con el título **Pedidos** y un conjunto de filas repetitivas que muestran un icono de camión, un folio y la leyenda *tocar para ver detalle*. Cada elemento es interactivo; al seleccionarlo, la aplicación emite una notificación en la parte inferior indicando cuál registro específico fue seleccionado.

![Lista de pedidos](img/lista-pedidos.png)

### Row + Expanded

El uso de `Expanded` dentro de una estructura `Row` permite distribuir el espacio disponible de manera eficiente: el contenedor del folio se ajusta a su contenido y la etiqueta **dron** se desplaza automáticamente hacia el extremo derecho, evitando superposiciones de texto.

![Fila con Expanded](img/row-con-expanded.png)

Al prescindir de `Expanded`, los textos se colocan de forma continua, provocando que los elementos excedan los límites de la pantalla si el contenido es muy largo o si la ventana se redimensiona. En el entorno web, este desbordamiento genera una advertencia gráfica de color amarillo con negro y un reporte detallado en la consola indicando la cantidad exacta de píxeles excedidos.

![Fila sin Expanded](img/row-sin-expanded.png)

![Aviso del error en la terminal](img/row-error-terminal.png)

### Switch

Implementa un control de activación para el parámetro **Envío urgente**, acompañado de una transición animada al alternar su estado. El componente almacena de forma interna el valor booleano y gestiona su actualización y repintado gráfico de manera inmediata cada vez que el usuario interactúa con él.

![Interruptor de envío urgente](img/switch.png)

### Dropdown

Funciona como un menú de selección desplegable que agrupa tres opciones de transporte: motocicleta, dron y camioneta. Su arquitectura separa el texto descriptivo visible para el usuario del valor interno asociado que se procesa en la lógica del sistema.

![Lista desplegable de medios](img/dropdown.png)

### AlertDialog

Al accionar el botón principal, se despliega una ventana modal superpuesta que solicita confirmación para procesar la petición, ofreciendo las alternativas **Cancelar** y **Sí**. La ejecución permanece pausada hasta que se selecciona una opción; si se confirma afirmativamente, se activa un aviso temporal de respuesta en la parte inferior de la pantalla.

![Botón Crear pedido](img/alert-boton.png)

![Alerta de confirmación](img/alert-dialogo.png)

![Aviso de abajo al confirmar](img/alert-snackbar.png)

### Navigator

Gestiona el flujo de navegación mediante una estructura de pila (`stack`). Al seleccionar un elemento de la lista principal, la vista de detalle se coloca en el nivel superior de la jerarquía, mostrando el identificador correspondiente y un control **Volver** que permite deshacer el cambio para regresar al listado anterior.

![Pantalla de la lista](img/nav-lista.png)

![Pantalla de detalle con el botón Volver](img/nav-detalle.png)

### CircularProgressIndicator

Representa un indicador gráfico de actividad asíncrona que se activa al interactuar con el botón de procesamiento. Durante la ejecución, el control bloquea la interacción y muestra un elemento de carga animado. Tras un intervalo simulado, el sistema oculta el indicador y actualiza la interfaz con el resultado final correspondiente.

![Estado de carga](img/carga-cargando.png)

![Resultado al terminar la carga](img/carga-resultado.png)

---

## Preguntas cortas

> **1. ¿Qué problema de mantenimiento ataca Flutter al existir web y móvil en el mismo producto?**

Permite centralizar el código base en un solo repositorio. Sin esta tecnología, sería obligatorio desarrollar y dar mantenimiento a interfaces independientes para cada plataforma (Android, iOS y web), duplicando esfuerzos ante cualquier ajuste en las reglas de negocio o en la estructura de datos proveniente del backend.

> **2. ¿Por qué Flutter dibuja sus propios controles en lugar de usar solo los nativos del sistema?**

Para garantizar consistencia visual y un rendimiento gráfico uniforme en cualquier dispositivo. Al renderizar directamente sobre el motor gráfico, la aplicación evita depender de las variaciones o limitaciones de los componentes nativos de cada sistema operativo.

> **3. ¿En qué se diferencian un `StatelessWidget` y un `StatefulWidget`?**

El primero está diseñado para interfaces estáticas que solo proyectan información externa sin mutaciones locales. El segundo incorpora un ciclo de vida con gestión de estado interno, permitiendo redibujar sectores específicos de la pantalla de forma dinámica mediante la función `setState`.

> **4. Si `flutter doctor` marca un problema en Android pero Chrome funciona, ¿se puede empezar la clase de widgets igual? ¿Qué no se podría hacer todavía?**

Sí es posible avanzar con las prácticas utilizando la plataforma web como entorno de ejecución. La limitación principal radica en la imposibilidad de compilar binarios nativos (`.apk`) o desplegar la solución en emuladores y dispositivos físicos Android hasta completar la configuración de las herramientas de desarrollo correspondientes.

> **5. ¿Por qué un `Column` sin `Expanded` a veces «desborda» la pantalla cuando se meten muchos hijos?**

Porque un componente `Column` distribuye a sus elementos hijos tomando como referencia el espacio físico que cada uno demanda de forma intrínseca. Si la sumatoria vertical supera las dimensiones disponibles del contenedor padre, el excedente queda fuera del área visible de renderizado.

> **6. ¿Qué widget se usaría para mostrar muchos folios con scroll, y cuál para avisar «pedido creado» sin cambiar de pantalla?**

Para la visualización de colecciones extensas con capacidad de desplazamiento se emplea un `ListView` en conjunto con elementos `ListTile`. Para notificaciones rápidas de confirmación se utiliza un `SnackBar`, el cual despliega un mensaje flotante temporal en la sección inferior.

> **7. ¿En qué se parece el ejemplo de `CircularProgressIndicator` a una llamada real al gateway?**

Comparte la misma secuencia lógica de control asíncrono: se inicia un estado de espera activa mientras el sistema procesa la solicitud externa, y una vez obtenida la respuesta (simulada en este caso con un retraso temporal), la interfaz se actualiza para reflejar el resultado obtenido.