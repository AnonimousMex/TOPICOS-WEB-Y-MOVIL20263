# Auditoría del proyecto con IA

Fecha: 2026-11-24. Evidencia en `evidencias/auditoria_ia/` (prompt con el paquete de contexto y la salida completa del modelo local).

## 1. Herramientas y modelos
| Herramienta | Modelo | Local o nube | Qué hizo |
|---|---|---|---|
| Ollama 0.40.18 (instalado con Homebrew) | `llama3.2` (3B, 2.0 GB) | **local** | IA A: auditó el paquete de contexto (`ollama run llama3.2`) |
| Claude Code | Claude | nube (de pago) | IA B: revisó el código completo y verificó cada hallazgo a mano |

No se usó un modelo de código mayor (`qwen2.5-coder:7b`) por espacio y tiempo; queda como mejora.

## 2. Qué se le pasó y qué se omitió
Se pasó (≈6 KB): dominio y arquitectura en una frase, lista de endpoints, árbol de archivos y fragmentos de `settings.py`, `cors.py`, `api.dart` y `pagos.py`.
Se omitió: `backend/.env`, `db.sqlite3`, historial de Git, keystores y credenciales. La `SECRET_KEY` que aparece es el valor de desarrollo `django-insecure-…` del repositorio.

## 3. Tabla de hallazgos (IA A contra IA B y contra el código)
| Hallazgo | IA A (llama3.2) | IA B (Claude) | ¿Lo vimos en el código? | Qué haremos |
|---|---|---|---|---|
| `DEBUG=True`, `SECRET_KEY` fija y `ALLOWED_HOSTS=['*']` | no lo vio | sí | **sí**, `tienda/settings.py:23-28` | declarar: valores de desarrollo |
| CORS abierto `*` | lo señaló solo como «archivo sospechoso», sin decir por qué | sí | **sí**, `catalogo/cors.py:16` | declarar |
| `@csrf_exempt` en 11 vistas | no | sí | **sí**, `views.py` (API con token en cabecera) | declarar |
| Sin idempotencia en el pago | no | sí | **sí**, `checkout` | pendiente |
| Sin verificación de correo | no | sí | **sí** | pendiente |
| Token en almacenamiento del navegador | no | sí | **sí**, `AlmacenSesion` | declarar |
| Dataset sintético: métricas no son rendimiento real | no | sí | **sí**, `ml/` | declarado |
| `localhost` en la app | no | sí (parcial) | **parcial**: solo valor por defecto en web; la APK usa `10.0.2.2` | sin cambio |

## 4. Falsos positivos de la IA A (refutados con el código)
1. **«El modelo .joblib en el servidor es riesgo alto de seguridad y escalabilidad.»** Falso: que el modelo viva en el servidor es el requisito del curso y lo que evita meterlo en la APK. El archivo pesa 33 KB y solo lo carga el servidor (`catalogo/recomendador.py`).
2. **«Falta de auditoría: no se realiza auditoría en la aplicación.»** Falso: existe el modelo `Auditoria`, el `AuditoriaMiddleware` (`catalogo/auditoria.py:13`, activado en `settings.py:45`) y el endpoint `/api/auditoria/` solo para ADMIN.
3. **«No se verifica la integridad de los datos.»** Falso: `catalogo/validacion.py` rechaza valores fuera de rango (por ejemplo `peso_kg` entre 0.05 y 200) con HTTP 400.
4. **«Falta de secretos en el código expone a inyección.»** Confundido: no es un hallazgo real; el hallazgo verdadero es lo contrario, una `SECRET_KEY` fija (ver tabla), que el modelo no detectó.
5. **«No se reescriben los archivos» como hallazgo:** ruido; repitió una instrucción del prompt como si fuera un problema.

Lectura: un modelo de 3B local sirve para obtener una lista inicial, pero inventa y omite; sin verificación en el código, imprime alucinaciones. Los hallazgos reales salieron de leer los archivos.

## 5. Cambios posteriores
Los hallazgos reales son decisiones de alcance (proyecto académico): se explican y se declaran, no se arreglan antes de la demo. Pendientes con motivo: idempotencia y verificación de correo (alcance); cookie httpOnly (requiere cambiar el cliente); un modelo de código mayor (espacio).

## 6. Cómo repetirla
```bash
brew install ollama
ollama serve &              # o brew services start ollama
ollama pull llama3.2
ollama run llama3.2 < evidencias/auditoria_ia/prompt_y_paquete.txt
```
Antes de la demo: `git pull`, `flutter analyze` y prueba de humo (recomendación, folio, chat, web y APK). Prueba de clon limpio hecha el 2026-11-24: `git clone` + `pip install -r requirements.txt` + `manage.py test` = 81 pruebas OK.
