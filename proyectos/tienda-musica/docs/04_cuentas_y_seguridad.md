# 04 · Cuentas, seguridad y bitácora

## Registro e inicio de sesión
- Registro con `nombre`, `correo` y `contrasena`. La contraseña debe tener **8 a 72 caracteres con mayúscula, minúscula y número**.
- La contraseña se guarda con **PBKDF2** (hash de Django); nunca en texto.
- Al iniciar sesión se genera un **token opaco aleatorio**. El cliente lo guarda y lo envía en `Authorization: Bearer <token>`; el servidor guarda solo su **SHA-256** y su vigencia es de **7 días**.
- **Bloqueo:** 5 intentos fallidos bloquean el acceso 15 minutos (`IntentosLogin`).
- Cerrar sesión invalida el token en el servidor; un token inválido o vencido responde 401.

## Roles
| Rol | Cómo se obtiene | Puede |
|---|---|---|
| CLIENTE | al registrarse | comprar, ver «Mis compras», usar el asistente |
| ADMIN (`is_staff`) | `python manage.py crear_admin correo@ejemplo.com` | además, ver la bitácora y las métricas del asistente |

## Bitácora de auditoría
`AuditoriaMiddleware` registra cada petición a la API: usuario, rol, método, ruta, estado, IP, duración y un identificador de petición (`X-Request-Id`). Se consulta con `GET /api/auditoria/` (últimos 100 registros, solo ADMIN: 401 sin sesión y 403 sin rol).

## Compra
- La compra exige sesión; el correo de confirmación va al correo de la cuenta y no a otro.
- Pago **simulado**: solo acepta tarjetas de prueba (por ejemplo `4242 4242 4242 4242`) y valida formato, vigencia y algoritmo de Luhn. **No se guarda el número completo ni el CVV**: solo la marca y los últimos 4 dígitos.
- La compra es atómica (todo o nada).

## Comparación con el proyecto Rumbo
Mismo esquema a escala de monolito: Rumbo usa bcrypt, JWT de 15 minutos con cookie `httpOnly` de renovación, verificación de correo y eventos de auditoría vía Redis; Tesitura usa PBKDF2, token opaco de 7 días y bitácora síncrona en la base.

## Pendientes de seguridad declarados
Ver [08 · Límites y mejoras](08_limites_y_mejoras.md).
