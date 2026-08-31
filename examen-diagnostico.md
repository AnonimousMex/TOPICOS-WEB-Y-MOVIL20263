# Examen Diagnóstico 2 — Fundamentos de Ingeniería de Software

**Instituto Tecnológico de Morelia**  
**Materia:** Tópicos Selectos de Tecnologías Web y Móvil  
**Profesor:** Jesús Eduardo Alcaraz Chávez  
**Nombre del alumno:** Diego Rivera Cisneros  
**Fecha:** 27/08/2026  

**Instrucciones:** Responde de manera clara y concisa a cada una de las siguientes preguntas abiertas. El propósito de esta evaluación es medir tus conocimientos previos en Ingeniería de Software.

---

### 1. Metodologías
**¿Cuál es la diferencia principal entre una metodología de desarrollo tradicional (como Cascada) y una metodología ágil (como Scrum) frente a los cambios en los requisitos?**  
Radica en la secuencia y la flexibilidad. Cascada sigue un flujo lineal en el que no se avanza sin terminar las fases previas, por lo que un cambio de requisitos tardío es costoso. Scrum es flexible: trabaja con entregables en ciclos cortos (sprints), lo que permite incorporar cambios en los requisitos al inicio de cada iteración.

### 2. Requerimientos
**Explica la diferencia entre requerimientos funcionales y no funcionales, dando un ejemplo de cada uno aplicable a una plataforma web.**  
El requerimiento funcional define qué debe hacer el sistema; el no funcional define cómo debe comportarse.  
* **Funcional:** Para el sistema de una agencia de viajes, durante el levantamiento el cliente indica que el sistema debe registrar reservas, cotizaciones, clientes, socios e ingresos.  
* **No funcional:** Una vez definido qué se hace, se pregunta cómo. Por ejemplo, bajo qué criterio una reserva se considera confirmada (a partir del primer pago y de qué monto), tiempos de respuesta, disponibilidad, etc.

### 3. Arquitectura
**Describe el modelo Cliente-Servidor y explica brevemente cómo se comunican el frontend y el backend en una aplicación web moderna.**  
El modelo Cliente-Servidor divide las responsabilidades entre el frontend (cliente) y el backend (servidor), que se comunican mediante protocolos de red para transferir datos. Lo más común es hacerlo a través de una API, donde el frontend envía peticiones con métodos HTTP y el backend responde, normalmente en formato JSON.

### 4. Bases de Datos
**¿En qué escenarios recomendarías utilizar una base de datos relacional (SQL) frente a una no relacional (NoSQL)?**  
Depende de la naturaleza de los datos. SQL es recomendable cuando se manejan transacciones complejas y se requiere una estructura clara, robusta y con integridad garantizada. NoSQL es más adecuado en proyectos con datos flexibles, esquemas cambiantes o gran volumen y escalabilidad horizontal.

### 5. APIs
**¿Qué es una API REST y qué papel fundamental juega en la integración entre una aplicación móvil y el backend?**  
Una API REST es una interfaz que expone recursos del backend a través de métodos HTTP (GET, POST, PUT, DELETE). Es el medio más común para conectar una aplicación móvil con el servidor: permite enviar, recibir y procesar información de forma estandarizada e independiente de la plataforma del cliente.

### 6. Control de Versiones
**Explica la importancia de utilizar Git en un equipo de desarrollo y describe brevemente qué es un "merge conflict".**  
A lo largo del desarrollo de un proyecto, los miembros del equipo van generando y compartiendo distintos cambios; algunos mejoran el proyecto y otros pueden afectarlo. Un control de versiones como Git, junto con un repositorio como GitHub, facilita recuperar avances perdidos, revisar el historial y aprobar nuevas mejoras.  
Un *merge conflict* ocurre cuando dos ramas modifican la misma porción de código de forma divergente y Git no puede fusionarlas automáticamente. Por ejemplo, si la rama A tiene una versión de un archivo y la rama C tiene otra distinta sobre las mismas líneas, al intentar fusionarlas hay conflicto: es necesario resolverlo manualmente para dejar una versión compatible.

### 7. Pruebas
**¿Qué son las pruebas unitarias (unit testing) y por qué son cruciales antes del paso a producción?**  
Son pruebas automatizadas que evalúan la unidad mínima ejecutable del código (una función o método de forma aislada). Verifican que, ante una entrada específica, el resultado sea el esperado. Son cruciales porque detectan errores de forma temprana, permiten refactorizar con confianza y evitan que defectos lleguen a producción.

### 8. POO: Encapsulamiento y Polimorfismo
**Define encapsulamiento y polimorfismo, y menciona cómo ayudan a crear un código más mantenible.**  
* **Encapsulamiento:** Consiste en agrupar dentro de una misma clase los datos (atributos) y el comportamiento (métodos) que operan sobre ellos, y ocultar los detalles internos exponiendo solo una interfaz pública controlada mediante modificadores de visibilidad (private, protected, public). Aíslan los cambios, reduciendo el acoplamiento.  
* **Polimorfismo:** Es la capacidad de que una misma operación se comporte de forma distinta según el tipo real del objeto que la ejecuta. Elimina condicionales por tipo, permitiendo añadir comportamientos sin tocar código existente.

### 9. Patrones de Diseño: MVC
**¿Qué es el patrón Modelo-Vista-Controlador (MVC) y cómo ayuda a organizar el código?**  
Es un patrón de arquitectura que divide la aplicación en tres capas:  
* **Modelo:** Representa datos y lógica de negocio. Accede a la base de datos, aplica reglas y valida. No conoce la interfaz.  
* **Vista:** Presenta la información al usuario (HTML, pantallas, plantillas). Solo muestra datos.  
* **Controlador:** Recibe peticiones, pide datos al Modelo y elige qué Vista renderizar.  
Ayuda separando responsabilidades, de modo que se puede cambiar la Vista sin tocar la lógica de negocio, favoreciendo la reutilización y el trabajo en paralelo.

### 10. Seguridad: Autenticación vs. Autorización
**Explica la diferencia técnica entre "autenticación" y "autorización".**  
* **Autenticación:** Responde a *¿quién es el usuario?* Ocurre siempre primero y se verifica mediante credenciales (contraseñas, biometría).  
* **Autorización:** Responde a *¿qué permisos tiene el usuario?* Ocurre después de la autenticación y se basa en roles y políticas de acceso a los recursos.
