# Decisiones tecnológicas — Caso de la empresa de entregas

**Diego Rivera Cisneros — 22121364.**

Propuesta escrita para el relato del profesor; no describe ni modifica el stack del proyecto grupal existente.

| Decisión | Propuesta y razón vinculada al caso | Qué haría revisar la elección |
| --- | --- | --- |
| Clientes | Panel web y aplicación móvil consumen el mismo estado del pedido. Cambia la representación, no el folio ni la autorización. | Necesidades de accesibilidad y operación offline de cada cliente. |
| Backend y lenguaje | Python con Django permite integrar el recomendador de scikit-learn y aprovechar autenticación, ORM y middleware sin reescribirlos. | Restricciones reales de experiencia del equipo o integración con una plataforma existente. |
| Organización | Monolito modular al inicio: controlador delgado, caso de uso, reglas y estrategias, integración y persistencia. | Despliegues de IA que interfieran con Pedidos o carga medida que exija escalar diferente. |
| API | Recursos HTTP con JSON y contrato documentado; creación y consulta de pedido separadas, códigos de error explícitos y transición compatible de versiones. | Un consumidor que requiera una representación agregada muy distinta. |
| Base | PostgreSQL compartido para pedidos, intentos de pago y sesiones en una operación con varias réplicas. Transacciones y restricciones protegen invariantes. SQLite basta en un laboratorio local de poca concurrencia, sin confundirlo con la configuración escalada. | Volumen de escrituras, latencia y necesidades operativas verificadas. |
| Autenticación | Sesiones seguras para el panel; un mecanismo de tokens con vencimiento y revocación para clientes que lo necesiten. Autorización del pedido en backend. | Requisitos de identidad de una organización o proveedor externo. |
| IA | Contrato interno de sugerencia y Adapter para cada proveedor; el modelo se carga por proceso y sus versiones se registran. Reglas obligatorias verifican la recomendación. | Cambio de capacidad de la flota o proveedor y desempeño medido. |
| Mapas | Adapter hacia proveedor; guardar coordenadas y estado propios, acotar tiempo y permitir ver información textual si no carga el mapa. | Cobertura, costo y calidad reales del proveedor, sin asumir una marca específica. |
| Tiempo real | Empezar con consulta periódica razonable; SSE o WebSocket solo si la frecuencia de seguimiento y la carga lo justifican. | Necesidad demostrada de posiciones con baja latencia y presupuesto de conexiones. |
| Pagos y avisos | Intento idempotente; transacción local corta y conciliación del banco; outbox/cola para avisos posteriores al commit. | Obligaciones del proveedor y volumen que exija separar workers. |
| Pruebas | Reglas de factibilidad y costo, contratos de API, concurrencia de pagos, autenticación, caída de IA y evaluación de modelos en datos independientes. | Incidentes observados que añadan casos de regresión. |
| Despliegue | Versiones fijadas, artefacto de modelo identificado, servidor de producción, migración coordinada y almacenamiento persistente compartido. | Métricas y restricciones del entorno elegido; no se despliega infraestructura en esta actividad. |

La elección no añade un patrón por cada carpeta. Cada separación corresponde a una variación del relato: nuevos medios, formatos de IA ajenos, varios clientes o fallos de red. La transacción cubre operaciones de la misma base y no el cobro remoto; ese límite se comprueba antes de diseñar la respuesta de éxito.

Fuentes: [caso y decisiones previas del profesor](https://ealcaraz85.github.io/topicoswebmobil/#actividades) y [transacciones de Django](https://docs.djangoproject.com/en/6.0/topics/db/transactions/).
