# 05 · API

Base: `http://<servidor>:8001/api` en desarrollo. Cuerpo y respuestas en JSON. Las rutas protegidas piden `Authorization: Bearer <token>`.

## Catálogo
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/productos/` | Lista y búsqueda con filtros (194 productos de 51 marcas) |
| GET | `/productos/<id>/` | Detalle de un producto |
| GET | `/facetas/` | Valores disponibles para los filtros |
| GET | `/destinos/` | Ciudades de destino con distancia, humedad y zona |

## Recomendador
| Método | Ruta | Cuerpo | Descripción |
|---|---|---|---|
| POST | `/envio/` | `producto_id`, `cantidad`, `destino` | Embalaje para un producto del catálogo; el servidor completa valor, peso, dimensiones y fragilidad |
| POST | `/recomendar/` | las 12 entradas | Vista previa del modelo + reglas sin registrar nada |
| POST | `/ubicacion/` | `lat`, `lon` | Ciudad cercana y distancia a la bodega (o `cobertura: false` fuera de México); no guarda nada |
| POST | `/pedidos/` | producto o entradas, `destino`, `cliente` | Registra una recomendación con folio |
| GET | `/pedidos/<folio>/` | — | Consulta por folio |

Respuesta típica de `/envio/`: `entradas`, `nivel_modelo`, `confianza`, `nivel_final`, `corregido_por_reglas`, `reglas`, `ranking`, `descripcion`, `costo_embalaje_mxn` y `razon`. Datos inválidos responden **400** con el detalle por campo.

## Compra (requiere sesión)
| Método | Ruta | Cuerpo | Descripción |
|---|---|---|---|
| POST | `/checkout/` | `lineas` (1 a 20), `cliente`, `tarjeta` | Valida, cobra (simulado), crea un pedido con folio por línea y envía el correo. 201 con `compra`, `pedidos`, `subtotal_mxn`, `embalaje_mxn`, `total_mxn`. 401 sin sesión; 409 sin existencias |
| GET | `/mis-compras/` | — | Compras del usuario |

## Cuentas
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/registro/` | Crea cuenta y devuelve `token` y `usuario` (201). 409 si el correo ya existe |
| POST | `/auth/login/` | Devuelve `token` y `usuario`. Bloqueo tras 5 fallos |
| POST | `/auth/logout/` | Invalida el token |
| GET | `/auth/yo/` | Usuario de la sesión actual |
| GET | `/auditoria/` | Bitácora (solo ADMIN) |

## Asistente
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/asistente/` | Cuerpo: `mensaje` (y `sesion`). 503 si está apagado |
| POST | `/asistente/feedback/` | 👍/👎 de una consulta |
| GET | `/asistente/metricas/` | Métricas (solo administrador) |
| GET | `/modelos/` | Métricas de los modelos; devuelve `null` en la parte del asistente si no está disponible |

## Códigos de estado usados
200 correcto · 201 creado · 400 datos inválidos · 401 sin sesión o token inválido · 403 sin permiso · 409 conflicto (correo repetido, sin existencias) · 503 asistente no disponible.
