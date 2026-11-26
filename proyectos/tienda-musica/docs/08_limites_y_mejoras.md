# 08 · Límites y mejoras

## Lo que no debe afirmarse
- **Datos y modelo:** el dataset es sintético y el nivel correcto sale de una fórmula con ruido. Las métricas (árbol 0.767, bosque 0.805, asistente ≈ 0.78) describen esos datos, no envíos ni usuarios reales. Las calificaciones, ventas, existencias y la humedad y zona de riesgo de cada ciudad son datos de demostración.
- **Reglas:** corrigieron el 2 % de 2,000 casos de prueba y no cambiaron la exactitud.
- **Servicios:** el pago es simulado y el correo está en modo consola salvo que se configure SMTP en `backend/.env`.
- **Pruebas:** ver [07](07_pruebas_y_evidencias.md#lo-que-no-se-probó).
- **Imágenes:** vienen de Wikimedia y muchas no son del artículo exacto ([créditos](../CREDITOS_IMAGENES.md)).

## Seguridad: valores de desarrollo
| Hallazgo | Dónde |
|---|---|
| `DEBUG = True`, `SECRET_KEY` en el código y `ALLOWED_HOSTS = ['*']` | `backend/tienda/settings.py` |
| `@csrf_exempt` en 11 vistas (API con token en cabecera, no con cookies) | `backend/catalogo/views.py` |
| CORS abierto (`*`) | `backend/catalogo/cors.py` |
| Sin llave de idempotencia en el pago | `checkout` |
| Sin verificación de correo ni recuperación de contraseña | cuentas |
| Token en el almacenamiento del navegador, no en cookie `httpOnly` | app |
| Sin Django REST Framework; Django Admin no registrado | backend |

Son declaraciones, no arreglos: el código sigue así.

## Qué se mejoraría primero
1. Entrenar con envíos reales y registrar si el embalaje recomendado fue el correcto, para poder reentrenar.
2. Configuración de producción: `DEBUG=False`, clave secreta propia, `ALLOWED_HOSTS` y CORS acotados, HTTPS.
3. Idempotencia en el pago, verificación de correo y cookie `httpOnly`.
4. PostgreSQL si hubiera varias réplicas.
5. Probar en un teléfono físico y con el GPS real.
6. Un modelo de código mayor para la auditoría con IA ([AUDITORIA_IA](../AUDITORIA_IA.md)).
