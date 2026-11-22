import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

/// Solo guarda el endpoint público. Los pedidos y modelos permanecen en Django.
class ConfiguracionServidor {
  final _preferencias = SharedPreferencesAsync();
  static const _clave = 'tesitura.api_url';

  Future<String> cargar() async {
    final guardada = await _preferencias.getString(_clave);
    if (guardada != null) {
      try {
        return normalizarUrlServidor(guardada);
      } on FormatException {
        // Una preferencia antigua inválida no impide abrir la tienda.
      }
    }
    return urlBasePorDefecto();
  }

  Future<void> guardar(String url) => _preferencias.setString(_clave, normalizarUrlServidor(url));
}

/// Guarda solo el token de sesión en el dispositivo (en web, almacenamiento local del navegador).
/// Compromiso: en web un token en almacenamiento local es legible por scripts de la misma página; Rumbo usa una cookie httpOnly
/// para evitarlo. Aquí no hay contenido de terceros y el token vence a los 7 días y se revoca al cerrar sesión.
class AlmacenSesion {
  final _preferencias = SharedPreferencesAsync();
  static const _clave = 'tesitura.token';

  Future<String?> leer() async {
    try {
      return await _preferencias.getString(_clave);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(String? token) async {
    try {
      token == null ? await _preferencias.remove(_clave) : await _preferencias.setString(_clave, token);
    } catch (_) {/* sin almacenamiento la sesión dura lo que dure la app */}
  }
}
