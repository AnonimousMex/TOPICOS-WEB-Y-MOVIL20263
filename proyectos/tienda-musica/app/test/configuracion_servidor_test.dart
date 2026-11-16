import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tienda_musica/api.dart';
import 'package:tienda_musica/configuracion_servidor.dart';
import 'package:tienda_musica/state.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('sin configuración guardada utiliza el servidor de la compilación', () async {
    expect(await ConfiguracionServidor().cargar(), urlBasePorDefecto());
  });

  test('la dirección se recupera desde otra instancia al volver a abrir', () async {
    await ConfiguracionServidor().guardar(' http://192.168.1.10:18000/api/ ');
    expect(await ConfiguracionServidor().cargar(), 'http://192.168.1.10:18000/api');
  });

  test('una URL raíz se convierte al endpoint API y descarta esquemas inválidos', () {
    expect(normalizarUrlServidor('http://192.168.1.10:18000'), 'http://192.168.1.10:18000/api');
    for (final valor in ['', 'localhost:8000/api', 'file:///api', 'https://', 'https://usuario:clave@ejemplo.com/api', 'https://ejemplo.com/api?token=abc']) {
      expect(() => normalizarUrlServidor(valor), throwsFormatException);
    }
  });

  test('una preferencia inválida no impide abrir la tienda', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({'tesitura.api_url': 'file:///vieja'});
    expect(await ConfiguracionServidor().cargar(), urlBasePorDefecto());
  });

  test('cambiar servidor guarda la dirección y actualiza las imágenes', () async {
    final configuracion = ConfiguracionServidor();
    final tienda = Tienda(RumboApi(baseUrl: 'http://anterior/api'), alCambiarServidor: configuracion.guardar);
    await tienda.cambiarServidor('http://nuevo:18000');
    expect(tienda.api.baseUrl, 'http://nuevo:18000/api');
    expect(await ConfiguracionServidor().cargar(), tienda.api.baseUrl);
    expect(resolverImagen('/img/producto.jpg'), 'http://nuevo:18000/img/producto.jpg');
    tienda.dispose();
  });

  test('si falla el guardado conserva el servidor anterior', () async {
    final tienda = Tienda(RumboApi(baseUrl: 'http://anterior/api'), alCambiarServidor: (_) async => throw Exception('Sin almacenamiento'));
    await expectLater(tienda.cambiarServidor('http://nuevo/api'), throwsException);
    expect(tienda.api.baseUrl, 'http://anterior/api');
    tienda.dispose();
  });
}
