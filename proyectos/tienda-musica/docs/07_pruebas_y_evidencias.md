# 07 · Pruebas y evidencias

## Pruebas automáticas
| Qué | Comando | Resultado |
|---|---|---|
| Backend (Django) | `cd backend && ./.venv/bin/python manage.py test` | 81 pruebas OK |
| Casos del asistente | `./.venv/bin/python manage.py evaluar_asistente` | 16 casos esperados |
| App (widgets) | `cd app && flutter test` | 23 pruebas |
| Recorrido en Android | `flutter drive --driver=test_driver/entrega_driver.dart --target=integration_test/compra_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8001/api` | «correcto» |

`CuentasTests` cubre registro, login, bloqueo, roles y bitácora; `AsistenteCaidoTests`, el asistente apagado o roto.

## Recorrido de punta a punta
`integration_test/compra_test.dart` recorre en Android: contraseña débil rechazada, registro, embalaje por ciudad, pago con tarjeta de prueba, folio con formato `MUS-AAAA-NNNNNN`, «Mis compras», consulta del folio en el chat y respuesta 401 tras cerrar sesión.

## Evidencias (`evidencias/`)
| Carpeta o archivo | Contenido |
|---|---|
| `web/` | Capturas del flujo en el navegador |
| `android/` | Capturas de la APK 1.0.1 (anterior al login) |
| `android_sesion/` | 10 capturas y `resultado.json` del recorrido con sesión en el emulador |
| `apk.json` | Versión, firma y SHA-256 de la APK |
| `modelos.json`, `flujo.json` | Métricas y un flujo de ejemplo |
| `auditoria_ia/` | Prompt y salida del modelo local de la auditoría con IA |

## Prueba de clon limpio
Con un `git clone` en una carpeta vacía, `pip install -r backend/requirements.txt` y `manage.py test`: 81 pruebas OK (2026-11-24).

## Lo que no se probó
- El archivo APK **release** ejecutando el recorrido completo (el recorrido se corrió con una compilación de depuración).
- Un teléfono físico.
- El GPS real (la ubicación por coordenadas se probó solo en pruebas automáticas).
- Un proveedor SMTP real (el correo se prueba en modo consola).
