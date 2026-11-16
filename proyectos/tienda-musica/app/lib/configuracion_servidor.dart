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
