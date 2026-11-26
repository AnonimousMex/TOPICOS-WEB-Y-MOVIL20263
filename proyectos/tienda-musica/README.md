# Tesitura · Tienda de música

**Diego Rivera Cisneros · 22121364 · Proyectos 1 y 2.**

Catálogo de instrumentos con backend Django/SQLite y cliente Flutter para web y Android. El recomendador decide el nivel de embalaje y seguro (`basico`, `reforzado`, `premium`); el asistente entrenado consulta productos y folios y utiliza un corpus propio para orientación de compra y cuidados.

**[Descargar Tesitura para Android](https://github.com/AnonimousMex/TOPICOS-WEB-Y-MOVIL20263/releases/download/tesitura-v1.1.0/Tesitura-Android.apk)**

La APK 1.1.0 se compila con `--dart-define=API_URL=http://10.0.2.2:8001/api` (el emulador de Android ve la Mac como 10.0.2.2); en un teléfono físico se usa la IP de la Mac. El teléfono debe estar en la misma red; la URL puede cambiarse con el botón de configuración del encabezado y se conserva al volver a abrir la aplicación.

## Instalación

Python 3.12 y Flutter compatible con `app/pubspec.yaml`.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py cargar_datos
python manage.py runserver 8001
```

En otra terminal:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8001/api
# Android: emulador configurado
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8001/api
```

Web y APK usan el mismo servidor (`localhost:8001` en la web, `10.0.2.2:8001` en el emulador). Los pedidos se guardan en la misma base SQLite: un folio creado desde web se puede consultar en Android. El backend y la Mac deben permanecer encendidos; en un teléfono físico se usa la IP de la Mac y la URL se cambia desde el icono del servidor. Los cambios de datos se consultan en el servidor; los cambios del código Flutter requieren recompilar web y reinstalar la APK.

Para servir la compilación web local en `http://localhost:8090`:

```bash
cd app
flutter build web --wasm --pwa-strategy=none --dart-define=API_URL=http://localhost:8001/api
python3 servir_web.py 8090 --aislado
```

## Modelos y reglas

Desde `backend/`:

```bash
python ml/generar_dataset.py --filas 10000 --semilla 7 --faltantes 0.02
python ml/entrenar_recomendador.py
python ml/entrenar_asistente.py
python ml/probar_modelo.py
```

El recomendador utiliza árbol o bosque y aplica reglas separadas en `catalogo/reglas.py`; devuelve confianza, ranking, decisión original, corrección, razón y plan. El asistente clasifica intenciones con su propio modelo; consulta datos del servidor y remite al recomendador cuando se requiere decidir embalaje.

El ejemplo del curso elige transporte; Tesitura elige protección y seguro del instrumento. Una guitarra de $9,000, 3 kg, 105 cm y 520 km, con fragilidad, humedad alta y zona de riesgo alta, permite demostrar la corrección hacia `premium` por las reglas. La respuesta real se conserva en las evidencias.

Los datos son de demostración y los pagos son simulados. El correo se configura mediante `TESITURA_SMTP_*` en `backend/.env`; las pruebas de entrega usan consola. Los modelos se entrenan en servidor, no dentro de Flutter.

## Pruebas y capturas

```bash
cd backend
python manage.py test
python manage.py evaluar_asistente
```

La prueba Flutter `app/integration_test/entrega_test.dart` se ejecuta contra la API de demostración y crea un pedido. Android puede consultar además el folio creado en web mediante `FOLIO_COMPARTIDO`. El driver guarda capturas y respuestas reales del servidor. Para repetirla, iniciar el backend de demostración en el puerto 18000:

```bash
cd app
# ChromeDriver debe estar escuchando en el puerto 4444 para la prueba web
TESITURA_EVIDENCE_DIR=../evidencias/web flutter drive -d chrome --web-port=5175 \
  --driver=test_driver/entrega_driver.dart --target=integration_test/entrega_test.dart \
  --dart-define=API_URL=http://192.168.101.28:18000/api
TESITURA_EVIDENCE_DIR=../evidencias/android flutter drive -d emulator-5580 \
  --driver=test_driver/entrega_driver.dart --target=integration_test/entrega_test.dart \
  --dart-define=API_URL=http://192.168.101.28:18000/api \
  --dart-define=FOLIO_COMPARTIDO=MUS-2026-000006
```

[Capturas web y Android](evidencias/README.md) · [Patrones web y móvil](ANALISIS_PATRONES.md) · [Métricas de entrenamiento](backend/ml/reportes/entrenamiento.md) · [Métricas de ambos modelos](evidencias/modelos.json).

## Imágenes

Fotos y logos de Wikimedia Commons; las imágenes de marca o referencia se identifican como tales y no necesariamente muestran el modelo exacto. Autoría, licencia y fuentes se conservan en [CREDITOS_IMAGENES.md](CREDITOS_IMAGENES.md). Precios, existencias, calificaciones y ventas son datos de demostración.


## Cuentas, roles y auditoría

- `POST /api/auth/registro/`, `/api/auth/login/`, `/api/auth/logout/`, `GET /api/auth/yo/`: token `Bearer` (se guarda solo su SHA-256, vence a los 7 días); contraseñas con hash PBKDF2; bloqueo de 15 min tras 5 fallos.
- Roles `CLIENTE` y `ADMIN` (`manage.py crear_admin correo`). Pagar exige sesión; `GET /api/mis-compras/` lista las compras de la cuenta; `GET /api/auditoria/` (bitácora: usuario, rol, ruta, estado, IP) solo para ADMIN.
- Código: `backend/catalogo/autenticacion.py`, `auditoria.py`; Flutter: `app/lib/pages/cuenta_page.dart`, `state.dart`.
- Documentación técnica por temas: [docs/](docs/README.md).


## Construir y actualizar la APK

```bash
cd app
flutter pub get
flutter build apk --release --dart-define=API_URL=http://10.0.2.2:8001/api
# salida: build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

La versión sale de `pubspec.yaml` (`1.1.0+3`: nombre visible + versionCode). `build/`, `.apk`, keystores y `.env` no se suben a Git; la APK se publica como release y su SHA-256 está en `evidencias/apk.json`. Está firmada con la clave de depuración y permite HTTP (`usesCleartextTraffic`) porque el servidor de pruebas es HTTP.

## Uso de IA en este proyecto

- **Desarrollo:** el código, las pruebas y la documentación se hicieron con ayuda de Claude Code (asistente de IA de pago, en la nube) bajo la dirección del autor, que revisó y ejecutó cada cambio. Ver `DISENO.md`.
- **Datos y entrenamiento propios:** el dataset sintético (`backend/ml/generar_dataset.py`), el entrenamiento y los `.joblib` se generan con scripts del repositorio, no vienen de ningún servicio externo.
- **Auditoría con IA:** ver `AUDITORIA_IA.md`.
