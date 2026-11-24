import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'configuracion_servidor.dart';
import 'ubicacion.dart';

class LineaCarrito {
  LineaCarrito(this.producto, this.cantidad);
  final Producto producto;
  int cantidad;
  double get subtotal => producto.precio * cantidad;
}

class MensajeChat {
  MensajeChat(this.texto, {required this.propio, this.respuesta});
  final String texto;
  final bool propio;
  final RespuestaAsistente? respuesta;
  int? feedback; // 1 útil, -1 no útil
}

/// Estado global: carrito y conversación del asistente (se conservan al navegar).
class Tienda extends ChangeNotifier {
  Tienda(this.api, {ServicioUbicacion? ubicacion, this.alCambiarServidor, AlmacenSesion? almacen, this.chatHabilitado = true}) : ubicacion = ubicacion ?? UbicacionReal(), _almacen = almacen;
  final RumboApi api;
  final ServicioUbicacion ubicacion;
  final Future<void> Function(String)? alCambiarServidor;
  final AlmacenSesion? _almacen;

  /// Interruptor del asistente: con `false` (flutter build web --dart-define=CHAT=false) desaparecen el botón y el panel de chat.
  /// Nada más depende del chat, así que catálogo, recomendador, carrito y cuenta funcionan igual.
  final bool chatHabilitado;

  // ----- cuenta y sesión
  Usuario? usuario;
  bool get conSesion => usuario != null;

  Future<void> _fijarSesion(Sesion s) async {
    api.token = s.token;
    usuario = s.usuario;
    correoCliente = s.usuario.correo;
    await _almacen?.guardar(s.token);
    notifyListeners();
  }

  Future<void> iniciarSesion(String correo, String contrasena) async => _fijarSesion(await api.login(correo, contrasena));
  Future<void> registrarse(String nombre, String correo, String contrasena) async => _fijarSesion(await api.registro(nombre, correo, contrasena));

  Future<void> cerrarSesion() async {
    try {
      await api.logout(); // revoca el token en el servidor
    } on ApiException {/* aunque falle la red, se cierra localmente */}
    api.token = null;
    usuario = null;
    correoCliente = '';
    await _almacen?.guardar(null);
    notifyListeners();
  }

  /// Al abrir la app: si hay un token guardado, el servidor confirma que sigue vigente.
  Future<void> restaurarSesion() async {
    final token = await _almacen?.leer();
    if (token == null) return;
    api.token = token;
    try {
      usuario = await api.yo();
      correoCliente = usuario!.correo;
    } on ApiException catch (e) {
      if (e.status == 401) {
        api.token = null;
        await _almacen?.guardar(null);
      }
    }
    notifyListeners();
  }

  Future<void> cambiarServidor(String url) async {
    final normalizada = normalizarUrlServidor(url);
    await alCambiarServidor?.call(normalizada);
    api.baseUrl = normalizada;
    notifyListeners();
  }

  /// Identifica la conversación para que el asistente recuerde el contexto (no es una cuenta ni un dato personal).
  final String sesion = 's${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(99999)}';
  /// Correo de la última compra: permite al asistente mostrarte TUS pedidos (rol cliente).
  String correoCliente = '';

  // ----- destino de entrega (ciudad o tu ubicación)
  DestinoElegido? destino;
  UbicacionInfo? ubicacionInfo;
  bool localizando = false;
  String? errorUbicacion;

  void elegirCiudad(String? ciudad) {
    destino = ciudad == null ? null : DestinoElegido.ciudad(ciudad);
    ubicacionInfo = null;
    errorUbicacion = null;
    notifyListeners();
  }

  /// Pide tu ubicación al GPS/navegador y la convierte en ciudad cercana y distancia. Solo vive en memoria.
  Future<bool> usarMiUbicacion() async {
    localizando = true;
    errorUbicacion = null;
    notifyListeners();
    try {
      final pos = await ubicacion.obtener();
      final info = await api.ubicacion(pos.lat, pos.lon);
      if (!info.cobertura) {
        errorUbicacion = info.mensaje ?? 'Tu ubicación está fuera de la zona de cobertura.';
        return false;
      }
      ubicacionInfo = info;
      destino = DestinoElegido.ubicacion(pos.lat, pos.lon, 'Mi ubicación (cerca de ${info.ciudadCercana})');
      return true;
    } on UbicacionException catch (e) {
      errorUbicacion = e.mensaje;
      return false;
    } on ApiException catch (e) {
      errorUbicacion = e.mensaje;
      return false;
    } finally {
      localizando = false;
      notifyListeners();
    }
  }

  final List<LineaCarrito> lineas = [];
  int get articulos => lineas.fold(0, (s, l) => s + l.cantidad);
  double get subtotal => lineas.fold(0.0, (s, l) => s + l.subtotal);

  void agregar(Producto p, [int cantidad = 1]) {
    final i = lineas.indexWhere((l) => l.producto.id == p.id);
    final maximo = p.existencias.clamp(1, 10);
    if (i >= 0) {
      lineas[i].cantidad = (lineas[i].cantidad + cantidad).clamp(1, maximo);
    } else {
      lineas.add(LineaCarrito(p, cantidad.clamp(1, maximo)));
    }
    notifyListeners();
  }

  void cambiarCantidad(LineaCarrito l, int cantidad) {
    l.cantidad = cantidad.clamp(1, l.producto.existencias.clamp(1, 10));
    notifyListeners();
  }

  void quitar(LineaCarrito l) {
    lineas.remove(l);
    notifyListeners();
  }

  void vaciar() {
    lineas.clear();
    notifyListeners();
  }

  // ----- chat
  final List<MensajeChat> chat = [
    MensajeChat('¡Hola! Soy el asistente de la tienda. Puedo buscar instrumentos por marca, tipo o presupuesto, mostrarte ofertas, consultar tu folio y resolver dudas de envíos, garantía y cuidados.', propio: false),
  ];
  bool chatAbierto = false;
  bool chatEnviando = false;
  final List<String> sugerenciasIniciales = const ['¿Qué ofertas tienen?', 'Busco una guitarra de menos de 6 mil pesos', '¿Qué modelos de Yamaha tienen?', '¿Cómo funcionan los envíos?'];

  Future<void> calificar(MensajeChat m, int valor) async {
    final id = m.respuesta?.consultaId;
    if (id == null || m.feedback != null) return;
    m.feedback = valor;
    notifyListeners();
    try {
      await api.feedback(id, valor);
    } on ApiException {
      m.feedback = null; // no se pudo registrar: que pueda reintentar
      notifyListeners();
    }
  }

  void alternarChat([bool? abierto]) {
    chatAbierto = abierto ?? !chatAbierto;
    notifyListeners();
  }

  Future<void> enviarChat(String texto) async {
    final t = texto.trim();
    if (t.isEmpty || chatEnviando) return;
    chat.add(MensajeChat(t, propio: true));
    chatEnviando = true;
    notifyListeners();
    try {
      final r = await api.preguntar(t, sesion: sesion, correo: correoCliente);
      chat.add(MensajeChat(r.respuesta, propio: false, respuesta: r));
    } on ApiException catch (e) {
      chat.add(MensajeChat('⚠ ${e.mensaje}', propio: false));
    } finally {
      chatEnviando = false;
      notifyListeners();
    }
  }
}

class TiendaScope extends InheritedNotifier<Tienda> {
  const TiendaScope({super.key, required Tienda tienda, required super.child}) : super(notifier: tienda);

  static Tienda of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TiendaScope>()!.notifier!;
  static Tienda leer(BuildContext context) => (context.getInheritedWidgetOfExactType<TiendaScope>()!).notifier!;
}
