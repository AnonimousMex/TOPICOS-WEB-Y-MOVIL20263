# Complemento — Qué problema aparece al usar mal un paradigma

**Nombre:** Diego Rivera Cisneros — **Matrícula:** 22121364.

La investigación previa ya incluye veinte lenguajes. Este complemento añade el riesgo al exagerar o usar mal su enfoque. Tipado, plataforma, técnica de concurrencia y patrón no son sinónimos de paradigma. RAII, BLoC, DI, transacciones y pipelines se citan como técnicas/patrones del ecosistema; no todos pertenecen a los 23 GoF.

| Lenguaje | Enfoque | Técnica o patrón | Riesgo concreto | Criterio de corrección |
| --- | --- | --- | --- | --- |
| Python | Imperativo, OOP y funcional | Decorator / Iterator | Tipado dinámico sin contratos permite errores tardíos. El estado global mutable dificulta aislar pruebas. | Validar fronteras, funciones pequeñas y tipos cuando aporten claridad. |
| JavaScript | Prototipos, funcional y eventos | Module / Observer | Mutar prototipos compartidos cambia código ajeno; callbacks sin manejo explícito pierden errores. | Módulos y composición; manejar errores de promesas. |
| TypeScript | Multiparadigma con comprobación estática | Strategy / Adapter | `any` y aserciones sin validar datos externos crean una seguridad aparente. | Validación en ejecución del contrato HTTP; tipos inferidos o comprobados. |
| Java | Clases, imperativo y funcional | Factory Method / Strategy | Herencia profunda acopla cambios y obliga a conocer toda la jerarquía. | Composición para variaciones independientes; interfaces con un propósito. |
| C# | OOP, genérico y funcional | DI / Observer | Interfaces para toda clase añaden navegación sin beneficio; suscripciones largas pueden retener objetos. | Extraer contratos por fronteras reales y gestionar desuscripción. |
| C++ | Procedural, objetos y genérico | RAII / PIMPL | Propiedad de recursos ambigua y herencia múltiple complicada vuelven frágil la vida de los objetos. | RAII, propiedad explícita y composición. |
| C | Imperativo y procedural | Opaque Pointer | Punteros y tamaño de buffers sin control permiten accesos fuera de límites. | Contratos de tamaño, manejo de recursos y herramientas de análisis. |
| Go | Procedural con concurrencia | Worker Pool / Pipeline | Lanzar goroutines sin cancelación puede dejar tareas bloqueadas y consumidores de memoria. | Contexto de cancelación y límites de concurrencia. |
| Rust | Imperativo, funcional y propiedad | Typestate / RAII | Abusar de referencias cruzadas y bloqueos hace complejo modelar el dominio. | Modelar propiedad y usar índices o mensajes cuando simplifiquen las relaciones. |
| PHP | Imperativo y objetos | Front Controller / Active Record | Scripts por trámite mezclan HTTP, consultas y negocio y duplican controles. | Usar router y middleware del framework y consultas parametrizadas. |
| Ruby | Objetos y metaprogramación | Active Record / Template Method | Generar demasiado comportamiento en ejecución dificulta seguir dependencias y errores. | Convenciones visibles y separar casos de uso de modelos excesivos. |
| Swift | Objetos, protocolos y funcional | MVVM / Coordinator | Demasiados protocolos y tipos genéricos pueden ocultar una pantalla sencilla. | Extraer dependencias por variación real; respetar la vida del estado de la vista. |
| Kotlin | Objetos y funcional | Adapter / Strategy | Extensiones dispersas y tareas lanzadas fuera de un ciclo de vida dificultan saber quién posee el comportamiento. | Concurrencia estructurada y ubicación predecible de utilidades. |
| Scala | OOP y funcional | Composición / Actor | Combinar demasiadas abstracciones funcionales y jerarquías vuelve difícil leer el flujo. | Convenciones del equipo y efectos explícitos con una abstracción consistente. |
| Haskell | Funcional puro y evaluación perezosa | Composición / separación de efectos | Acumular cálculos diferidos puede aumentar consumo de memoria. | Medir evaluación y usar estructuras o acumulaciones estrictas donde haga falta. |
| Elixir | Funcional y procesos BEAM | Supervision Tree | Crear procesos y reintentos sin límites puede amplificar una falla externa. | Supervisión con presupuestos, aislamiento y colas acotadas. |
| Dart | Objetos y asincronía | BLoC / Repository | Guardar red, SQL y estado de dominio dentro del widget dificulta reconstrucción y pruebas. | Estado y datos fuera de la vista cuando la complejidad lo requiera. |
| R | Vectorial y funcional | Pipeline | Cadenas que copian conjuntos grandes sin observar memoria hacen costoso un análisis. | Medir asignaciones y transformar solo columnas necesarias. |
| SQL | Declarativo | Transacción / consultas agrupadas | Ocultar acceso a datos detrás de bucles de aplicación produce N+1; el esquema no evita consultas costosas. | Diseñar consultas, claves y transacciones según el caso y revisar planes. |
| Lua | Imperativo y funciones embebibles | Adapter / Interpreter | Tablas globales y scripts con efectos mezclados producen dependencias implícitas con el host. | API de integración acotada y estado local explícito. |

El costo no es inevitable por escoger el lenguaje: depende de las decisiones. Por ejemplo, herencia no obliga a jerarquías profundas, programación funcional no exige ignorar memoria y usar un ORM no garantiza un número razonable de consultas.

Se consultó la estructura de la actividad compartida por [César Díaz](https://github.com/Cesaredmyt/Topicos-Selectos-de-Tecnologias-Web-y-Movil/blob/6397468bd6c15e68a7a4fdee786917b470c825e7/Trabajo_31_Agosto.md). La selección de veinte lenguajes corresponde a [la investigación ya presente](../../investigacion-paradigmas.md); el análisis se redactó para esta entrega. El criterio de composición y rechazo de sobreingeniería se apoya en [los apuntes del profesor](https://ealcaraz85.github.io/topicoswebmobil/#actividades).
