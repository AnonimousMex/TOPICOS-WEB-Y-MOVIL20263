import 'package:geolocator/geolocator.dart';

class UbicacionException implements Exception {
  UbicacionException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Servicio de ubicación inyectable: la app real usa el GPS / el navegador; las pruebas usan uno falso.
abstract class ServicioUbicacion {
  Future<({double lat, double lon})> obtener();
}

class UbicacionReal implements ServicioUbicacion {
  @override
  Future<({double lat, double lon})> obtener() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw UbicacionException('El servicio de ubicación está apagado. Actívalo para usar tu ubicación.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      throw UbicacionException('No diste permiso de ubicación. Puedes elegir tu ciudad de la lista.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)));
      return (lat: p.latitude, lon: p.longitude);
    } catch (_) {
      throw UbicacionException('No se pudo obtener tu ubicación. Elige tu ciudad de la lista.');
    }
  }
}
