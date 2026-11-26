# 01 · Arquitectura

## Decisión
Un **monolito Django** con una API JSON, una base **SQLite** y un único cliente **Flutter** que se compila para web y Android. No hay microservicios: el flujo (catálogo → recomendación → pago → folio) es lineal y comparte los mismos datos, así que separarlo agregaría red, despliegue y fallas sin beneficio.

```
Flutter (web / Android)  ──HTTP + JSON──►  Django (backend/)
                                              ├─ catalogo/      vistas, modelos, reglas, pagos, cuentas
                                              ├─ ml/modelos/    recomendador_arbol.joblib · asistente.joblib
                                              ├─ catalogo/corpus/  documentos que consulta el asistente
                                              └─ db.sqlite3     productos, pedidos, sesiones, bitácora
```

## Módulos del backend (`backend/catalogo/`)
| Archivo | Responsabilidad |
|---|---|
| `views.py`, `urls.py` | Rutas y vistas de la API |
| `models.py` | Producto, Pedido, Compra, Correo, Sesion, IntentosLogin, Auditoria, ConsultaAsistente, ContextoAsistente |
| `envios.py`, `validacion.py` | Arma las 12 entradas del modelo desde la base y valida rangos |
| `recomendador.py`, `reglas.py`, `niveles.py` | Modelo, reglas de negocio y plan de cada nivel de embalaje |
| `pagos.py`, `correos.py` | Pago simulado y correo (consola o SMTP) |
| `autenticacion.py`, `auditoria.py` | Cuentas, token, bloqueo y bitácora |
| `asistente.py` | Asistente conversacional (8 capas) |
| `cors.py` | Cabeceras CORS para desarrollo |

## Patrones de diseño usados
- **Strategy** (`niveles.py`): cada nivel de embalaje arma su propio plan.
- **Adapter** (`RecomendadorIA`): interfaz común para el árbol, el bosque y las reglas.
- **Decorator** (`RecomendadorConRespaldo`): si el modelo falla, cae al recomendador de reglas simples.
- **Factory** con `lru_cache` (`obtener_recomendador`): crea y reutiliza el recomendador.
- **Middleware** (`AuditoriaMiddleware`): registra cada petición.
- En Flutter: **Facade** (`RumboApi`), **Observer** (`Tienda` + `TiendaScope`) e inyección de dependencias. Detalle en [ANALISIS_PATRONES](../ANALISIS_PATRONES.md).

## Flujo de una compra
1. El cliente inicia sesión (la compra exige cuenta).
2. Elige un producto, la cantidad y una ciudad de destino.
3. La app llama a `POST /api/envio/` con producto, cantidad y destino. El servidor toma de la base el valor, el peso, las dimensiones y la fragilidad; **el cliente no puede enviar esos valores**.
4. El servidor arma las 12 entradas, consulta el árbol y aplica las reglas; responde nivel, confianza, razón y costo.
5. En el carrito el costo de embalaje se suma al total; al pagar, `POST /api/checkout/` **recalcula** el embalaje en el servidor.
6. La compra es atómica: si una línea falla, no se crea nada. Cada línea recibe un folio `MUS-AAAA-NNNNNN` y se envía el correo de confirmación.
7. El folio se consulta en «Mis compras» y se puede preguntar al asistente.

## Aislamiento del asistente
Ninguna pieza del flujo de compra importa `asistente.py`. La importación es perezosa (`_servicio_asistente()`), y con `TESITURA_ASISTENTE=off` las rutas del asistente responden 503 con un mensaje claro mientras todo lo demás sigue funcionando. Ver [03 · Asistente](03_asistente.md).
