import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// URL base: se puede cambiar al compilar (--dart-define=API_URL=...) o desde la app.
/// En el emulador Android, 10.0.2.2 es la Mac; en web y escritorio, localhost.
String urlBasePorDefecto() {
  const definida = String.fromEnvironment('API_URL');
  if (definida.isNotEmpty) return definida;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://localhost:8000/api';
}

/// Origen del servidor (sin /api): las imágenes llegan como rutas relativas (/img/...).
String origenServidor = '';

String normalizarUrlServidor(String valor) {
  final uri = Uri.tryParse(valor.trim());
  if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    throw const FormatException('Escribe una dirección http:// o https:// sin usuario, parámetros ni fragmentos.');
  }
  final path = uri.path.replaceAll(RegExp(r'/+$'), '');
  return uri.replace(path: path.isEmpty ? '/api' : path).toString();
}

String? resolverImagen(String? ruta) {
  if (ruta == null || ruta.isEmpty) return null;
  return ruta.startsWith('http') ? ruta : '$origenServidor$ruta';
}

class ApiException implements Exception {
  ApiException(this.mensaje, {this.campos = const {}, this.status = 0});
  final String mensaje;
  final Map<String, String> campos;
  final int status;
  @override
  String toString() => mensaje;
}

class Producto {
  Producto.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        nombre = j['nombre'] as String,
        marca = j['marca'] as String,
        categoria = j['categoria'] as String,
        subcategoria = (j['subcategoria'] as String?) ?? '',
        descripcion = (j['descripcion'] as String?) ?? '',
        precio = (j['precio_mxn'] as num).toDouble(),
        precioOriginal = (j['precio_original_mxn'] as num?)?.toDouble(),
        descuento = (j['descuento_pct'] as num?)?.toInt() ?? 0,
        peso = (j['peso_kg'] as num?)?.toDouble() ?? 0,
        dimensionMax = (j['dimension_max_cm'] as num?)?.toInt() ?? 0,
        fragil = (j['fragil'] as bool?) ?? true,
        existencias = (j['existencias'] as num?)?.toInt() ?? 0,
        rating = (j['rating'] as num?)?.toDouble() ?? 4.5,
        vendidos = (j['vendidos'] as num?)?.toInt() ?? 0,
        envioGratis = (j['envio_gratis'] as bool?) ?? false,
        imagenUrl = resolverImagen(j['imagen_url'] as String?),
        imagenMini = resolverImagen(j['imagen_mini_url'] as String?),
        imagenCredito = j['imagen_credito'] as String?,
        imagenFuente = j['imagen_fuente'] as String?,
        imagenNivel = j['imagen_nivel'] as String?,
        marcaLogo = resolverImagen(j['marca_logo'] as String?),
        similares = ((j['similares'] as List?) ?? const []).map((s) => Producto.fromJson(s as Map<String, dynamic>)).toList();

  final int id;
  final String nombre, marca, categoria, subcategoria, descripcion;
  final double precio, peso, rating;
  final double? precioOriginal;
  final int descuento, dimensionMax, existencias, vendidos;
  final bool fragil, envioGratis;
  final String? imagenUrl, imagenMini, imagenCredito, imagenFuente, imagenNivel, marcaLogo;
  final List<Producto> similares;

  bool get agotado => existencias <= 0;
}

class Marca {
  Marca(this.nombre, this.total, [this.logo]);
  final String nombre;
  final int total;
  final String? logo;
}

class Facetas {
  Facetas.fromJson(Map<String, dynamic> j)
      : marcas = (j['marcas'] as List).map((m) => Marca(m['marca'] as String, m['total'] as int, resolverImagen(m['logo'] as String?))).toList(),
        categorias = {for (final c in (j['categorias'] as List)) c['categoria'] as String: c['total'] as int},
        precioMin = (j['precio_min'] as num).toDouble(),
        precioMax = (j['precio_max'] as num).toDouble();
  final List<Marca> marcas;
  final Map<String, int> categorias;
  final double precioMin, precioMax;
}

class Destino {
  Destino(this.ciudad, this.km);
  final String ciudad;
  final int km;
}

/// Filtros del listado (se traducen a parámetros de la API).
class Filtro {
  const Filtro({this.q = '', this.categoria, this.marcas = const {}, this.min, this.max, this.oferta = false, this.envioGratis = false, this.disponible = false, this.orden = 'relevancia'});
  final String q, orden;
  final String? categoria;
  final Set<String> marcas;
  final double? min, max;
  final bool oferta, envioGratis, disponible;

  Filtro copiar({String? q, String? categoria, bool limpiarCategoria = false, Set<String>? marcas, double? min, double? max, bool limpiarPrecio = false, bool? oferta, bool? envioGratis, bool? disponible, String? orden}) => Filtro(
        q: q ?? this.q,
        categoria: limpiarCategoria ? null : (categoria ?? this.categoria),
        marcas: marcas ?? this.marcas,
        min: limpiarPrecio ? null : (min ?? this.min),
        max: limpiarPrecio ? null : (max ?? this.max),
        oferta: oferta ?? this.oferta,
        envioGratis: envioGratis ?? this.envioGratis,
        disponible: disponible ?? this.disponible,
        orden: orden ?? this.orden,
      );

  Map<String, String> toQuery() => {
        if (q.isNotEmpty) 'q': q,
        'categoria': ?categoria,
        if (marcas.isNotEmpty) 'marca': marcas.join(','),
        if (min != null) 'min': '${min!.round()}',
        if (max != null) 'max': '${max!.round()}',
        if (oferta) 'oferta': '1',
        if (envioGratis) 'envio_gratis': '1',
        if (disponible) 'disponible': '1',
        'orden': orden,
      };

  int get activos => (categoria != null ? 1 : 0) + marcas.length + ((min != null || max != null) ? 1 : 0) + (oferta ? 1 : 0) + (envioGratis ? 1 : 0) + (disponible ? 1 : 0);
}

class Envio {
  const Envio({required this.tipo, required this.valor, required this.peso, required this.dimensionMax, required this.distancia, required this.fragil, this.productoId, this.cantidad = 1, this.humedad = 'media', this.zona = 'baja', this.urgente = false, this.usado = false});
  final String tipo;
  final double valor, peso;
  final int dimensionMax, distancia;
  final bool fragil, urgente, usado;
  final int? productoId;
  final int cantidad;
  final String humedad, zona;

  Map<String, dynamic> toJson() => {
        'cantidad': cantidad,
        'humedad_destino': humedad,
        'zona_riesgo': zona,
        'urgente': urgente,
        'condicion': usado ? 'usado' : 'nuevo',
        'tipo': tipo,
        'valor_mxn': valor,
        'peso_kg': peso,
        'dimension_max_cm': dimensionMax,
        'distancia_km': distancia,
        'fragil': fragil,
        'producto_id': ?productoId,
      };
}

class Regla {
  Regla.fromJson(Map<String, dynamic> j)
      : codigo = j['regla'] as String,
        efecto = j['efecto'] as String,
        motivo = j['motivo'] as String;
  final String codigo, efecto, motivo;
}

class PlanEmbalaje {
  PlanEmbalaje.fromJson(Map<String, dynamic> j)
      : materiales = (j['materiales'] as List).cast<String>(),
        cobertura = j['cobertura_seguro'] as String,
        horas = (j['tiempo_preparacion_h'] as num).toDouble();
  final List<String> materiales;
  final String cobertura;
  final double horas;
}

class Recomendacion {
  Recomendacion.fromJson(Map<String, dynamic> j)
      : nivelModelo = j['nivel_modelo'] as String,
        confianza = (j['confianza'] as num).toDouble(),
        nivelFinal = j['nivel_final'] as String,
        corregido = j['corregido_por_reglas'] as bool,
        reglas = (j['reglas'] as List).map((r) => Regla.fromJson(r)).toList(),
        ranking = (j['ranking'] as List).map((r) => MapEntry(r['nivel'] as String, (r['probabilidad'] as num).toDouble())).toList(),
        descripcion = j['descripcion'] as String?,
        costo = (j['costo_embalaje_mxn'] as num?)?.toInt() ?? 0,
        razon = j['razon'] as String?,
        plan = j['plan'] == null ? null : PlanEmbalaje.fromJson(j['plan'] as Map<String, dynamic>);
  final String nivelModelo, nivelFinal;
  final String? descripcion, razon;
  final PlanEmbalaje? plan;
  final double confianza;
  final bool corregido;
  final int costo;
  final List<Regla> reglas;
  final List<MapEntry<String, double>> ranking;
}

class PedidoRegistrado {
  PedidoRegistrado.fromJson(Map<String, dynamic> j)
      : folio = j['folio'] as String,
        estado = j['estado'] as String,
        producto = j['producto'] as String?,
        destino = (j['destino'] as String?) ?? '',
        cantidad = (j['cantidad'] as num?)?.toInt() ?? 1,
        recomendacion = Recomendacion.fromJson(j['recomendacion']);
  final String folio, estado, destino;
  final String? producto;
  final int cantidad;
  final Recomendacion recomendacion;
}

class DestinoElegido {
  const DestinoElegido.ciudad(String this.ciudad)
      : lat = null,
        lon = null,
        etiqueta = '';
  const DestinoElegido.ubicacion(double this.lat, double this.lon, this.etiqueta) : ciudad = null;
  final String? ciudad;
  final double? lat, lon;
  final String etiqueta;
  bool get esUbicacion => ciudad == null;
  String get nombre => ciudad ?? etiqueta;
  Map<String, dynamic> toJson() => {'destino': ciudad ?? 'ubicacion', 'lat': ?lat, 'lon': ?lon};
}

class Tarjeta {
  const Tarjeta({required this.numero, required this.titular, required this.vencimiento, required this.cvv});
  final String numero, titular, vencimiento, cvv;
  Map<String, dynamic> toJson() => {'numero': numero, 'titular': titular, 'vencimiento': vencimiento, 'cvv': cvv};
}

class UbicacionInfo {
  UbicacionInfo.fromJson(Map<String, dynamic> j)
      : cobertura = j['cobertura'] as bool,
        mensaje = j['mensaje'] as String?,
        ciudadCercana = j['ciudad_cercana'] as String?,
        kmCiudad = (j['km_a_ciudad'] as num?)?.toInt(),
        kmBodega = (j['km_bodega'] as num?)?.toInt();
  final bool cobertura;
  final String? mensaje, ciudadCercana;
  final int? kmCiudad, kmBodega;
}

class CompraInfo {
  CompraInfo.fromJson(Map<String, dynamic> j)
      : referencia = j['referencia'] as String,
        correo = j['correo'] as String,
        destino = j['destino'] as String,
        pagoMarca = j['pago']['marca'] as String,
        pagoUltimos4 = j['pago']['ultimos4'] as String,
        pagoReferencia = j['pago']['referencia'] as String,
        correoEstado = j['correo_estado'] as String,
        modoCorreo = j['modo_correo'] as String;
  final String referencia, correo, destino, pagoMarca, pagoUltimos4, pagoReferencia, correoEstado, modoCorreo;
}

class ResultadoCompra {
  ResultadoCompra.fromJson(Map<String, dynamic> j)
      : compra = CompraInfo.fromJson(j['compra'] as Map<String, dynamic>),
        pedidos = (j['pedidos'] as List).map((p) => PedidoRegistrado.fromJson(p)).toList(),
        subtotal = (j['subtotal_mxn'] as num).toDouble(),
        embalaje = (j['embalaje_mxn'] as num).toDouble(),
        total = (j['total_mxn'] as num).toDouble();
  final CompraInfo compra;
  final List<PedidoRegistrado> pedidos;
  final double subtotal, embalaje, total;
}

class TarjetaChat {
  TarjetaChat.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        nombre = j['nombre'] as String,
        marca = j['marca'] as String,
        categoria = j['categoria'] as String,
        precio = (j['precio_mxn'] as num).toDouble(),
        precioOriginal = (j['precio_original_mxn'] as num?)?.toDouble(),
        rating = (j['rating'] as num).toDouble(),
        imagenUrl = resolverImagen(j['imagen_mini_url'] as String? ?? j['imagen_url'] as String?);
  final int id;
  final String? imagenUrl;
  final String nombre, marca, categoria;
  final double precio, rating;
  final double? precioOriginal;
}

class RespuestaAsistente {
  RespuestaAsistente.fromJson(Map<String, dynamic> j)
      : intencion = j['intencion'] as String,
        respuesta = j['respuesta'] as String,
        aviso = j['aviso'] as String?,
        accion = j['accion'] as String?,
        consultaId = (j['consulta_id'] as num?)?.toInt(),
        requiere = j['requiere'] as String?,
        productos = ((j['productos'] as List?) ?? const []).map((p) => TarjetaChat.fromJson(p as Map<String, dynamic>)).toList(),
        sugerencias = ((j['sugerencias'] as List?) ?? const []).cast<String>(),
        fuentes = ((j['fuentes'] as List?) ?? const []).map((f) => f['titulo'] as String).toList(),
        capas = ((j['capas'] as List?) ?? const []).map((c) => MapEntry(c['capa'] as String, c['detalle'] as String)).toList();
  final String intencion, respuesta;
  final String? aviso, accion, requiere;
  final int? consultaId;
  final List<TarjetaChat> productos;
  final List<String> sugerencias, fuentes;
  final List<MapEntry<String, String>> capas;
}

/// Facade: el resto de la app no conoce HTTP ni JSON, solo estos métodos.
class Usuario {
  const Usuario({required this.id, required this.nombre, required this.correo, required this.rol});
  final int id;
  final String nombre, correo, rol; // rol: CLIENTE | ADMIN
  bool get esAdmin => rol == 'ADMIN';
  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(id: j['id'] as int, nombre: j['nombre'] as String, correo: j['correo'] as String, rol: j['rol'] as String);
}

class Sesion {
  const Sesion(this.token, this.usuario);
  final String token;
  final Usuario usuario;
}

class CompraResumen {
  const CompraResumen({required this.referencia, required this.total, required this.destino, required this.pedidos});
  final String referencia, destino;
  final double total;
  final List<PedidoRegistrado> pedidos;
}

class RegistroAuditoria {
  const RegistroAuditoria({required this.usuario, required this.rol, required this.metodo, required this.ruta, required this.status, required this.ip, required this.fecha});
  final String usuario, rol, metodo, ruta, ip, fecha;
  final int status;
}

class RumboApi {
  RumboApi({String? baseUrl, http.Client? cliente})
      : _baseUrl = baseUrl ?? urlBasePorDefecto(),
        _http = cliente ?? http.Client() {
    this.baseUrl = _baseUrl; // fija también el origen de las imágenes
  }

  String _baseUrl;
  String get baseUrl => _baseUrl;
  set baseUrl(String v) {
    _baseUrl = normalizarUrlServidor(v);
    origenServidor = _baseUrl.replaceAll(RegExp(r'/api$'), '');
  }

  final http.Client _http;

  /// Token de la sesión iniciada; se manda en `Authorization: Bearer` en cada llamada. Lo fija `Tienda`.
  String? token;

  Future<Map<String, dynamic>> _pedir(Future<http.Response> Function() llamada) async {
    final http.Response r;
    try {
      r = await llamada().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder.');
    } catch (_) {
      throw ApiException('No se pudo conectar con $baseUrl. ¿Está encendido el servidor?');
    }
    Map<String, dynamic> cuerpo;
    try {
      cuerpo = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respuesta inesperada del servidor (${r.statusCode}).');
    }
    if (r.statusCode >= 400) {
      final campos = (cuerpo['campos'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? <String, String>{};
      final detalle = campos.values.isNotEmpty ? campos.values.first : null;
      throw ApiException(detalle ?? (cuerpo['error'] as String?) ?? 'Error ${r.statusCode}', campos: campos, status: r.statusCode);
    }
    return cuerpo;
  }

  Map<String, String> get _json => {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  Map<String, String> get _auth => {if (token != null) 'Authorization': 'Bearer $token'};

  Future<List<Producto>> productos([Filtro filtro = const Filtro()]) async {
    final c = await _pedir(() => _http.get(Uri.parse('$baseUrl/productos/').replace(queryParameters: filtro.toQuery())));
    return (c['resultados'] as List).map((p) => Producto.fromJson(p)).toList();
  }

  Future<Producto> producto(int id) async => Producto.fromJson(await _pedir(() => _http.get(Uri.parse('$baseUrl/productos/$id/'))));

  Future<Facetas> facetas() async => Facetas.fromJson(await _pedir(() => _http.get(Uri.parse('$baseUrl/facetas/'))));

  Future<List<Destino>> destinos() async {
    final c = await _pedir(() => _http.get(Uri.parse('$baseUrl/destinos/')));
    return (c['destinos'] as List).map((d) => Destino(d['ciudad'] as String, d['km'] as int)).toList();
  }

  /// Embalaje recomendado para un producto del catálogo hacia una ciudad o tu ubicación.
  Future<Recomendacion> cotizarEnvio(int productoId, int cantidad, DestinoElegido destino) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/envio/'), headers: _json, body: jsonEncode({'producto_id': productoId, 'cantidad': cantidad, ...destino.toJson()})));
    return Recomendacion.fromJson(c);
  }

  /// Convierte coordenadas en ciudad cercana y distancia a la bodega (el servidor no las guarda).
  Future<UbicacionInfo> ubicacion(double lat, double lon) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/ubicacion/'), headers: _json, body: jsonEncode({'lat': lat, 'lon': lon})));
    return UbicacionInfo.fromJson(c);
  }

  Future<ResultadoCompra> comprar({
    required String cliente,
    required String correo,
    required DestinoElegido destino,
    required Tarjeta tarjeta,
    required List<({int productoId, int cantidad})> lineas,
  }) async {
    final c = await _pedir(() => _http.post(
          Uri.parse('$baseUrl/checkout/'),
          headers: _json,
          body: jsonEncode({
            'cliente': cliente,
            'correo': correo,
            ...destino.toJson(),
            'tarjeta': tarjeta.toJson(),
            'lineas': [for (final l in lineas) {'producto_id': l.productoId, 'cantidad': l.cantidad}],
          }),
        ));
    return ResultadoCompra.fromJson(c);
  }

  // Cotizador con formulario completo (Proyecto 1)
  Future<Recomendacion> recomendar(Envio e) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/recomendar/'), headers: _json, body: jsonEncode(e.toJson())));
    return Recomendacion.fromJson(c);
  }

  Future<PedidoRegistrado> registrar(Envio e) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/pedidos/'), headers: _json, body: jsonEncode(e.toJson())));
    return PedidoRegistrado.fromJson(c);
  }

  Future<RespuestaAsistente> preguntar(String mensaje, {String sesion = '', String correo = ''}) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/asistente/'), headers: _json, body: jsonEncode({'mensaje': mensaje, 'sesion': sesion, 'correo': correo})));
    return RespuestaAsistente.fromJson(c);
  }

  // ----- cuentas y sesión
  Future<Sesion> registro(String nombre, String correo, String contrasena) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/auth/registro/'), headers: _json, body: jsonEncode({'nombre': nombre, 'correo': correo, 'contrasena': contrasena})));
    return Sesion(c['token'] as String, Usuario.fromJson(c['usuario']));
  }

  Future<Sesion> login(String correo, String contrasena) async {
    final c = await _pedir(() => _http.post(Uri.parse('$baseUrl/auth/login/'), headers: _json, body: jsonEncode({'correo': correo, 'contrasena': contrasena})));
    return Sesion(c['token'] as String, Usuario.fromJson(c['usuario']));
  }

  Future<Usuario> yo() async => Usuario.fromJson((await _pedir(() => _http.get(Uri.parse('$baseUrl/auth/yo/'), headers: _auth)))['usuario']);

  Future<void> logout() async {
    await _pedir(() => _http.post(Uri.parse('$baseUrl/auth/logout/'), headers: _json));
  }

  Future<List<CompraResumen>> misCompras() async {
    final c = await _pedir(() => _http.get(Uri.parse('$baseUrl/mis-compras/'), headers: _auth));
    return (c['compras'] as List)
        .map((x) => CompraResumen(referencia: x['referencia'], total: (x['total_mxn'] as num).toDouble(), destino: x['destino'] ?? '', pedidos: (x['pedidos'] as List).map((p) => PedidoRegistrado.fromJson(p)).toList()))
        .toList();
  }

  Future<List<RegistroAuditoria>> auditoria() async {
    final c = await _pedir(() => _http.get(Uri.parse('$baseUrl/auditoria/'), headers: _auth));
    return (c['registros'] as List)
        .map((a) => RegistroAuditoria(usuario: a['usuario'] ?? '', rol: a['rol'] ?? '', metodo: a['metodo'], ruta: a['ruta'], status: a['status'], ip: a['ip'] ?? '', fecha: a['fecha']))
        .toList();
  }

  Future<void> feedback(int consultaId, int valor) async {
    await _pedir(() => _http.post(Uri.parse('$baseUrl/asistente/feedback/'), headers: _json, body: jsonEncode({'consulta_id': consultaId, 'valor': valor})));
  }
}
