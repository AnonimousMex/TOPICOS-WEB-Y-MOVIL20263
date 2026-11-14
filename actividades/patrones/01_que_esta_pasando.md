# Actividad — ¿Qué está pasando aquí?

**Nombre:** Diego Rivera Cisneros  
**Matrícula:** 22121364  
**Equipo:** no indicado en el repositorio; documento individual para integrar al trabajo del equipo.


**Caso:** empresa de entregas de los apuntes. Análisis documental; no se afirma haber participado en una sesión presencial ni ejecutado el proyecto del equipo.

## Paso 1. Separar los inconvenientes

| Punto | Inconveniente principal | Qué cambia | Qué conviene conservar | Qué está mezclado |
| --- | --- | --- | --- | --- |
| 1 | Cada trámite repite sesión y bitácora. | Caducidad, permisos y registro. | Los casos de uso. | Entrada HTTP, políticas y negocio. |
| 2a | Un bloque enorme decide cómo transportar. | Vehículos y formas de planear. | El flujo de registrar el pedido. | Orquestación y algoritmos concretos. |
| 2b | Cada IA entrega otro vocabulario. | Proveedor y formato. | El contrato interno de sugerencia. | Protocolo ajeno y conceptos del negocio. |
| 3 | El mapa y los reportes consultan directamente la base. | Formatos de presentación y consultas. | Las reglas y el pedido persistido. | SQL, vista y cálculo de ETA. |
| 4 | Cobro, alta y correo se ejecutan juntos y se repiten. | Destinatarios, pasarela y reintentos. | Una sola operación de negocio por intento. | Consistencia local, efecto bancario y notificaciones. |
| 5 | Cada cliente reúne muchos datos por separado. | Pantallas y representaciones. | Folio, estado y medio. | Datos de negocio y composición por pantalla. |
| 6 | Fallar IA o mapas bloquea consultas independientes. | Disponibilidad y latencia de terceros. | Consulta de pedidos guardados. | Recursos críticos y tareas auxiliares. |
| 7 | Se propone una arquitectura extensa para descargar una guía. | El formato del documento. | Autenticar y consultar el pedido. | Una necesidad pequeña con mecanismos sin justificación. |

**Quinto medio:** el relato no permite contar archivos con exactitud. Hoy habría que editar el selector y posiblemente el cálculo y sus consumidores. El riesgo es el número de responsabilidades que obliga a revisar, no inventar una cifra.

**Cambio de `route_hint` a `vehicle`:** si el protocolo atraviesa todas las capas, puede romper web y móvil. Si se transforma al entrar, el cambio queda en la integración y los clientes conservan el mismo contrato.

**Correo caído:** no debe deshacer un pedido confirmado ni provocar un segundo cargo. Hay que registrar el aviso pendiente y reintentarlo; la base local no puede deshacer por sí sola una operación bancaria.

**IA caída:** sí debe poder consultarse un pedido de ayer: su consulta necesita la base, no inferencia nueva. Si hoy no puede, hay una dependencia innecesaria.

## Paso 2. Catálogo GoF y límites

| Punto | Patrón GoF o ninguno | Justificación | Vecino descartado |
| --- | --- | --- | --- |
| 1 | Chain of Responsibility | Las políticas se ordenan y pueden detener la petición. El framework ya proporciona middleware. | No construir Template Method solo para copiar sesión. Front Controller pertenece al diseño web, no a los 23 GoF. |
| 2a | Strategy | Cada medio implementa su planeación bajo un contrato. | State representa cambios de estado; aquí se elige un algoritmo. |
| 2b | Adapter | Traduce el JSON/XML ajeno a `Sugerencia`. | Facade simplifica operaciones; no garantiza traducir contratos. |
| 3 | Ninguno resuelve por sí solo la persistencia y la vista. | Separar consultas, caso de uso y representación; Repository y Template View son patrones fuera del catálogo GoF. | No llamar «MVC» a una carpeta que sigue ejecutando SQL desde HTML. |
| 4 | Observer para avisos; ninguno para atomicidad o doble cargo. | Los interesados reaccionan al evento; transacciones e idempotencia cubren otros riesgos. | Observer no es Unit of Work y no crea una cola automáticamente. |
| 5 | Ninguno. | Un recurso agregado o BFF reúne la información de cada cliente. | Factory construye objetos, no reduce doce viajes HTTP. |
| 6 | Ninguno. | Timeouts, aislamiento y Circuit Breaker controlan fallos de red. | Proxy podría intermediar, pero por sí solo no establece tolerancia a fallos. |
| 7 | Ninguno obligatorio. | Basta recuperar datos autorizados y renderizar una guía. | Command no exige Event Sourcing ni CQRS. |

## Paso 3. Primer corte y dos clientes

Elegiría aislar la consulta del pedido: recuperar una representación ya guardada sin volver a pedir una sugerencia a la IA. Es un cambio pequeño y permite comprobar que un fallo del recomendador no bloquea seguimiento. Mantendría los folios y las reglas vigentes; no sustituiría toda la base ni modificaría el proyecto del equipo para esta entrega documental.

El panel puede renderizar HTML con mapa y el teléfono pedir JSON con folio, estado y ETA. Ambos deben leer el mismo estado autorizado. Que el mapa no cargue puede cambiar la presentación, pero no el estado del pedido ni los permisos para consultarlo.

**Fuente:** [actividad en los apuntes del profesor](https://ealcaraz85.github.io/topicoswebmobil/#orgeff9f7e).
