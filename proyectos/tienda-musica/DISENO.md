# Diseño de Tesitura (Proyectos 1 y 2)

Documento de diseño previo al desarrollo con IA: qué decide el recomendador, qué guarda el backend y cómo se conecta la app.

## Qué decide el recomendador
Dado un producto, una cantidad y una ciudad de destino, decide el nivel de embalaje y seguro: `basico`, `reforzado` o `premium`.
Flujo: **pregunta → API → .joblib → reglas → JSON → pantalla**.

1. La app envía `POST /api/envio/` con producto, cantidad y ciudad.
2. El servidor toma de la base el valor, el peso y la fragilidad (`catalogo/envios.py`) y arma las 12 entradas del modelo.
3. El árbol de decisión (`ml/modelos/recomendador_arbol.joblib`, 33 KB) devuelve nivel y confianza.
4. Las reglas R1 a R8 (`catalogo/reglas.py`) revisan al modelo; solo R6 baja el nivel.
5. Se guarda el folio `MUS-AAAA-NNNNNN` y se responde JSON con nivel, confianza, `corregido`, razón y costo.
6. Flutter muestra «Embalaje Premium +$299» con la razón.

El `.joblib` y el corpus del asistente viven **en el servidor**; la app (web o APK) no los lleva.

## Modelos Django (`catalogo/models.py`)
Producto, Pedido (folio, usuario, nivel, total), Compra, Correo, ConsultaAsistente, ContextoAsistente, Sesion (token hasheado), IntentosLogin, Auditoria.

## Endpoints principales (JSON)
| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/productos/`, `/api/productos/<id>/`, `/api/facetas/` | catálogo, detalle y filtros |
| GET | `/api/destinos/` | ciudades de destino |
| POST | `/api/envio/` | recomendación de embalaje (producto + cantidad + ciudad) |
| POST | `/api/recomendar/` | recomendación con las 12 entradas completas (formulario de bodega) |
| POST | `/api/checkout/` | pago simulado y folio (requiere sesión) |
| GET | `/api/pedidos/<folio>/` | consulta por folio |
| POST | `/api/auth/registro/`, `/api/auth/login/`, `/api/auth/logout/` | cuentas |
| GET | `/api/auth/yo/`, `/api/mis-compras/` | sesión actual y compras del usuario |
| POST | `/api/asistente/` | asistente (puede apagarse; responde 503 JSON) |
| GET | `/api/auditoria/` | bitácora (solo ADMIN) |

(La lista exacta está en `backend/catalogo/urls.py`.)

## Pantallas Flutter
Inicio y catálogo, detalle con ciudad y embalaje, carrito, compra con tarjeta de prueba, folio, Mis compras, cuenta (login/registro), chat.

## Decisiones
- Monolito Django + SQLite: un solo servidor; no se justifican microservicios (ver `GUIA_DEFENSA.md`).
- Pago simulado: solo tarjetas de prueba, nunca se guarda número ni CVV.
- El asistente no decide embalaje; si se apaga (`TESITURA_ASISTENTE=off`), el resto sigue funcionando.
