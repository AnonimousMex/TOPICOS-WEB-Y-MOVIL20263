# Auditoría del proyecto con IA

Estado honesto: este informe tiene una parte hecha y una parte **pendiente de ejecutar con un modelo local**.

## 1. Herramientas y modelos
| Herramienta | Modelo | Local o nube | Estado |
|---|---|---|---|
| Revisión asistida con Claude Code | Claude | nube (de pago) | **hecha**: hallazgos de la sección 3, verificados a mano en el código |
| Ollama | `llama3.2` (y opcional `qwen2.5-coder:7b`) | local | **pendiente**: no estaba instalado en la máquina; ver sección 6 |
| Segunda IA (Gemini en AI Studio u otra gratuita) | — | nube | **pendiente** |

## 2. Qué se le pasó y qué se omitió
Se pasó: dominio (tienda de instrumentos, recomendador de embalaje), arquitectura en una frase (monolito Django + API JSON + Flutter web/Android), lista de endpoints, árbol de archivos y fragmentos de `settings.py`, `cors.py`, `views.py` y `api.dart`.
Se omitió: `backend/.env`, la base `db.sqlite3`, el historial de Git, keystores y cualquier credencial.

## 3. Hallazgos verificados en el código
| # | Hallazgo | Severidad | Dónde | ¿Confirmado? | Qué se hizo |
|---|---|---|---|---|---|
| 1 | `DEBUG = True`, `SECRET_KEY` en el código y `ALLOWED_HOSTS = ['*']` | alta | `backend/tienda/settings.py:23-28` | sí | declarado como valores de desarrollo; sin cambiar |
| 2 | `@csrf_exempt` en 11 vistas | media | `backend/catalogo/views.py` | sí (es API con token en cabecera, no cookies) | declarado |
| 3 | CORS abierto (`*`) | media | `backend/catalogo/cors.py:16` | sí | declarado; para desarrollo |
| 4 | Sin idempotencia en el pago | media | `views.py` (`checkout`) | sí | pendiente |
| 5 | Sin verificación de correo ni recuperación de contraseña | media | cuentas | sí | pendiente |
| 6 | Token en almacenamiento del navegador, no cookie httpOnly | media | `app/lib` (`AlmacenSesion`) | sí | declarado |
| 7 | Dataset sintético: las métricas (0.767 / 0.805 / 0.78) no son rendimiento real | media | `ml/` | sí | declarado en las láminas |
| 8 | `localhost` en la app | baja | `app/lib/api.dart:15` | parcial: es solo el valor por defecto en web; el APK se compila con `API_URL=10.0.2.2` | sin cambio |

## 4. Falsos positivos (a completar con la salida real del modelo local)
Estos son los que un modelo pequeño suele inventar en este tipo de repo; **hay que anotar aquí los que realmente salgan y refutarlos con archivo**:
- «El modelo `.joblib` va dentro del APK»: falso; `GUIA_DEFENSA.md` §13 y `app/lib` no lo cargan, vive en el servidor.
- «Hay microservicios/gateway»: falso; es un monolito Django (`backend/manage.py`, una sola app `catalogo`).
- «El número de tarjeta se guarda»: falso; `catalogo/pagos.py` valida y descarta número y CVV (docstring línea 6; `tests.py` prueba solo tarjetas de prueba).

## 5. Cambios posteriores
Los hallazgos 1 a 6 son decisiones de alcance (proyecto académico): se explican, no se arreglan. Antes de la demo: `git pull`, `flutter analyze` y prueba de humo (recomendación, folio, chat, web y APK).

## 6. Cómo completar la auditoría local
```bash
brew install ollama        # o instalador de ollama.com
ollama pull llama3.2
ollama run llama3.2        # pegar el prompt de abajo + el paquete de contexto
```
Prompt: *«Audita este proyecto. Da hallazgos numerados con severidad (alta/media/baja), archivo sospechoso, evidencia, riesgo y cómo verificarlo en 5 minutos. Separa hecho con evidencia de hipótesis. No reescribas ni inventes archivos. Cierra con 5 comprobaciones manuales antes de la demo.»*
Después: repetir con otra IA, cruzar en una tabla (Hallazgo · IA A · IA B · ¿Lo vimos en el código? · Qué haremos) y anotar al menos dos falsos positivos en la sección 4.

Fecha de esta versión: 2026-11-24.
