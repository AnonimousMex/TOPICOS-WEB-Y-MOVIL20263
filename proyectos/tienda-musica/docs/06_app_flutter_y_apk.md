# 06 · App Flutter y APK

Una sola base de código Dart para web y Android. La lógica de negocio vive en el servidor; la app solo presenta y llama a la API.

## Estructura (`app/lib/`)
| Ruta | Contenido |
|---|---|
| `main.dart` | Arranque, inyección de la API, el almacén de sesión y el interruptor del chat |
| `api.dart` | Fachada `RumboApi` con todas las llamadas HTTP y la URL base por defecto |
| `state.dart` | Estado de la tienda (`Tienda`, `TiendaScope`, patrón Observer) |
| `configuracion_servidor.dart` | Guarda la URL del servidor y el token de sesión (`tesitura.token`) |
| `pages/` | Inicio, listado, producto, carrito, compra, cuenta y recomendador |
| `widgets/` | Marco, chat, tarjeta de pago, selector de destino, logo, tarjetas de producto |

## URL del servidor
| Dónde corre la app | URL |
|---|---|
| Chrome en la misma Mac | `http://localhost:8001/api` |
| Emulador de Android | `http://10.0.2.2:8001/api` (`10.0.2.2` es la Mac vista desde el emulador) |
| Teléfono físico | `http://<IP de la Mac>:8001/api` en la misma red |

Se define al compilar con `--dart-define=API_URL=…` y se puede cambiar dentro de la app con el icono del servidor; el valor se conserva.

## Web
```bash
cd app
flutter pub get
flutter build web --wasm --pwa-strategy=none --dart-define=API_URL=http://localhost:8001/api
python3 servir_web.py 8090 --aislado     # http://localhost:8090
```
Con `--dart-define=CHAT=false` se oculta el chat.

## APK
```bash
cd app
flutter build apk --release --dart-define=API_URL=http://10.0.2.2:8001/api
# salida: app/build/app/outputs/flutter-apk/app-release.apk
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```
- La versión sale de `pubspec.yaml` (`1.1.0+3`: nombre visible y `versionCode`).
- Flutter compila el Dart a código nativo (arm64-v8a, armeabi-v7a y x86_64, ≈54 MB), Gradle (`assembleRelease`) lo empaqueta y lo firma con la **clave de depuración**.
- `applicationId`: `mx.tienda.tienda_musica`. El manifiesto permite tráfico HTTP (`usesCleartextTraffic`) porque el servidor de pruebas no usa HTTPS.
- El modelo `.joblib` **no va en la APK**: vive en el servidor.
- La APK no se guarda en el repositorio: se publica en Releases (`tesitura-v1.1.0`) y `evidencias/apk.json` guarda su SHA-256.
- Una APK firmada con otra clave no se puede actualizar encima: hay que desinstalar la anterior (`adb uninstall mx.tienda.tienda_musica`).

## Emulador
```bash
export ANDROID_HOME=~/IA/.tools/android-sdk ANDROID_AVD_HOME=~/IA/.tools/android-avd
export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH
emulator -avd Rumbo_API_35 -no-snapshot
adb install -r ~/Documents/TOPICOSWEB/Tesitura-demo.apk
adb shell am start -n mx.tienda.tienda_musica/.MainActivity
```
(Las rutas son las del entorno del autor.)
