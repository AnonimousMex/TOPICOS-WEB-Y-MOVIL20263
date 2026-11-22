import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tienda_musica/api.dart';
import 'package:tienda_musica/main.dart';
import 'package:tienda_musica/ubicacion.dart';
import 'package:tienda_musica/widgets/comunes.dart';
import 'package:tienda_musica/widgets/desplazamiento.dart';

Map<String, dynamic> _prod(int id, String nombre, String marca, double precio, {double? original, int desc = 0}) => {
      'id': id, 'nombre': nombre, 'marca': marca, 'categoria': 'guitarra', 'subcategoria': 'Guitarras eléctricas',
      'descripcion': 'Guitarra de prueba.', 'precio_mxn': precio, 'precio_original_mxn': original, 'descuento_pct': desc,
      'peso_kg': 3.6, 'dimension_max_cm': 102, 'fragil': true, 'existencias': 8, 'rating': 4.7, 'vendidos': 540, 'envio_gratis': true,
      'imagen_url': null,
    };

final _p1 = _prod(1, 'Guitarra eléctrica Gibson Les Paul', 'Gibson', 69990, original: 79990, desc: 12);
final _p2 = _prod(2, 'Guitarra eléctrica Fender Stratocaster', 'Fender', 21990);

const _premium = {
  'nivel_modelo': 'reforzado', 'confianza': 0.61, 'nivel_final': 'premium', 'corregido_por_reglas': true,
  'descripcion': 'Estuche rígido y seguro total.', 'costo_embalaje_mxn': 299,
  'razon': 'El modelo (modelo_arbol) sugirió «reforzado» con 61 % de confianza. Las reglas lo ajustaron a «premium».',
  'plan': {'nivel': 'premium', 'materiales': ['Estuche rígido con espuma a medida'], 'cobertura_seguro': 'Seguro total', 'tiempo_preparacion_h': 1.0, 'costo_mxn': 299},
  'reglas': [{'regla': 'R1_VALOR_ALTO', 'efecto': 'sube a premium', 'motivo': 'Valor alto.'}],
  'ranking': [{'nivel': 'reforzado', 'probabilidad': 0.61}, {'nivel': 'premium', 'probabilidad': 0.3}],
};

http.Response _json(Object o, [int code = 200]) => http.Response(jsonEncode(o), code, headers: {'content-type': 'application/json; charset=utf-8'});

class _UbicacionFalsa implements ServicioUbicacion {
  _UbicacionFalsa({this.falla = false});
  final bool falla;
  @override
  Future<({double lat, double lon})> obtener() async {
    if (falla) throw UbicacionException('No diste permiso de ubicación.');
    return (lat: 19.7, lon: -101.2);
  }
}

class _Falso {
  _Falso({this.caido = false});
  final bool caido;
  final List<Uri> llamadas = [];
  final List<Map<String, dynamic>> cuerpos = [];

  RumboApi get api => RumboApi(
        baseUrl: 'http://x/api',
        cliente: MockClient((r) async {
          llamadas.add(r.url);
          if (r.method == 'POST') cuerpos.add(jsonDecode(r.body) as Map<String, dynamic>);
          if (caido) throw Exception('sin red');
          final ruta = r.url.path;
          if (ruta.endsWith('/facetas/')) {
            return _json({'marcas': [{'marca': 'Gibson', 'total': 1, 'logo': null}, {'marca': 'Fender', 'total': 1, 'logo': null}], 'categorias': [{'categoria': 'guitarra', 'total': 2}], 'precio_min': 100.0, 'precio_max': 80000.0});
          }
          if (ruta.endsWith('/destinos/')) return _json({'destinos': [{'ciudad': 'Monterrey', 'km': 900}, {'ciudad': 'Morelia', 'km': 5}]});
          if (ruta.endsWith('/ubicacion/')) return _json({'cobertura': true, 'lat': 19.7, 'lon': -101.2, 'ciudad_cercana': 'Morelia', 'km_a_ciudad': 3, 'km_bodega': 6, 'humedad': 'media', 'zona': 'baja'});
          if (RegExp(r'/productos/\d+/$').hasMatch(ruta)) return _json({..._p1, 'similares': [_p2]});
          if (ruta.endsWith('/productos/')) return _json({'total': 2, 'resultados': [_p1, _p2]});
          if (ruta.endsWith('/envio/')) return _json({'entradas': {}, ..._premium});
          if (ruta.endsWith('/recomendar/')) return _json({'entradas': {}, ..._premium});
          if (ruta.endsWith('/pedidos/')) return _json({'folio': 'MUS-2026-000009', 'estado': 'registrado', 'producto': null, 'destino': '', 'cantidad': 1, 'recomendacion': _premium}, 201);
          if (ruta.endsWith('/auth/login/') || ruta.endsWith('/auth/registro/')) {
            final c = jsonDecode(r.body) as Map<String, dynamic>;
            if (c['contrasena'] == 'Mala12345') return _json({'error': 'Correo o contraseña incorrectos.', 'codigo': 'NO_AUTORIZADO'}, 401);
            return _json({'token': 'tok-123', 'usuario': {'id': 1, 'nombre': c['nombre'] ?? 'Diego', 'correo': c['correo'], 'rol': 'CLIENTE'}}, ruta.endsWith('/registro/') ? 201 : 200);
          }
          if (ruta.endsWith('/auth/logout/')) return _json({'ok': true});
          if (ruta.endsWith('/checkout/')) {
            if (r.headers['Authorization'] != 'Bearer tok-123') return _json({'error': 'Inicia sesión para comprar.'}, 401);
            final tarjeta = jsonDecode(r.body)['tarjeta'] as Map<String, dynamic>;
            if ((tarjeta['numero'] as String).endsWith('0002')) {
              return _json({'error': 'Pago rechazado', 'mensaje': 'Tu banco rechazó la tarjeta.', 'campos': {'tarjeta': 'Tu banco rechazó la tarjeta.'}}, 402);
            }
            return _json({
              'compra': {'referencia': 'CMP-2026-000001', 'cliente': 'Diego', 'correo': 'diego@ejemplo.com', 'destino': 'Monterrey', 'pago': {'estado': 'aprobado', 'marca': 'visa', 'ultimos4': '4242', 'referencia': 'PAY-AB12CD34'}, 'correo_estado': 'simulado', 'modo_correo': 'consola'},
              'pedidos': [{'folio': 'MUS-2026-000007', 'estado': 'registrado', 'producto': 'Guitarra eléctrica Gibson Les Paul', 'destino': 'Monterrey', 'cantidad': 1, 'recomendacion': _premium}],
              'subtotal_mxn': 69990.0, 'embalaje_mxn': 299.0, 'total_mxn': 70289.0,
            }, 201);
          }
          if (ruta.endsWith('/asistente/feedback/')) return _json({'ok': true});
          if (ruta.endsWith('/asistente/')) {
            final m = jsonDecode(r.body)['mensaje'] as String;
            if (m.contains('embalaje')) {
              return _json({'intencion': 'pedir_recomendacion', 'respuesta': 'Lo calcula el recomendador.', 'accion': 'abrir_recomendador', 'confianza': 0.9, 'consulta_id': 3, 'capas': [{'capa': 'router', 'detalle': 'Intención detectada'}], 'sugerencias': [], 'fuentes': []});
            }
            if (m.contains('oferta')) {
              return _json({'intencion': 'ofertas', 'respuesta': 'Estas son las mejores ofertas:', 'confianza': 0.9, 'consulta_id': 4, 'productos': [_p1], 'sugerencias': ['¿Cuáles son los más vendidos?'], 'fuentes': [], 'capas': []});
            }
            return _json({'intencion': 'saludo', 'respuesta': '¡Hola! Soy el asistente.', 'confianza': 0.9, 'consulta_id': 5, 'capas': [], 'sugerencias': [], 'fuentes': []});
          }
          return _json({'error': 'no'}, 404);
        }),
      );
}

Future<_Falso> _abrir(WidgetTester t, {bool caido = false, bool ubicacionFalla = false, Size tamano = const Size(1280, 3200)}) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final f = _Falso(caido: caido);
  await t.pumpWidget(TiendaApp(api: f.api, ubicacion: _UbicacionFalsa(falla: ubicacionFalla)));
  await t.pumpAndSettle();
  return f;
}

Future<void> _iniciarSesion(WidgetTester t, {String clave = 'Clave1234'}) async {
  await t.tap(find.byKey(const Key('ingresar')));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('login-correo')), 'diego@ejemplo.com');
  await t.enterText(find.byKey(const Key('login-clave')), clave);
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('login-enviar')));
  await t.pumpAndSettle();
}

Future<void> _abrirProducto(WidgetTester t) async {
  await t.tap(find.byKey(const Key('producto-1')).first);
  await t.pumpAndSettle();
}

Future<void> _elegirMonterrey(WidgetTester t) async {
  await t.tap(find.byKey(const Key('destino')));
  await t.pumpAndSettle();
  await t.tap(find.text('Monterrey · 900 km').last);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('inicio construye las secciones lejanas solo al desplazarse', (t) async {
    await _abrir(t, tamano: const Size(1280, 800));
    final ultimaSeccion = find.byWidgetPredicate((w) => w is Seccion && w.titulo == 'Teclados y pianos');
    expect(ultimaSeccion, findsNothing);
    final scroll = find.descendant(of: find.byType(ListaSuave), matching: find.byType(Scrollable)).first;
    await t.scrollUntilVisible(ultimaSeccion, 400, scrollable: scroll);
    expect(ultimaSeccion, findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('inicio: marcas, ofertas y más vendidos', (t) async {
    await _abrir(t);
    expect(find.text('Marcas populares'), findsOneWidget);
    expect(find.text('Ofertas del día'), findsOneWidget);
    expect(find.byKey(const Key('marca-Gibson')), findsOneWidget);
    expect(find.text('12% OFF'), findsWidgets);
    expect(find.text('TESITURA'), findsWidgets); // marca de la tienda en el encabezado
  });

  testWidgets('error de red muestra mensaje y reintentar', (t) async {
    await _abrir(t, caido: true);
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('buscar y filtrar por marca envía los parámetros a la API', (t) async {
    final f = await _abrir(t);
    await t.enterText(find.byKey(const Key('busqueda')), 'guitarra');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('2 resultados'), findsOneWidget);
    expect(f.llamadas.any((u) => u.queryParameters['q'] == 'guitarra'), isTrue);
    await t.tap(find.byKey(const Key('filtro-marca-Gibson')));
    await t.pumpAndSettle();
    expect(f.llamadas.last.queryParameters['marca'], 'Gibson');
  });

  testWidgets('producto: el recomendador decide por ciudad y muestra razón y plan de embalaje', (t) async {
    await _abrir(t);
    await _abrirProducto(t);
    await _elegirMonterrey(t);
    expect(find.text('Embalaje Premium'), findsOneWidget);
    expect(find.byKey(const Key('correccion')), findsOneWidget); // las reglas corrigieron al modelo
    expect(find.textContaining('Las reglas lo ajustaron'), findsWidgets); // razón del modelo en texto
    await t.tap(find.byKey(const Key('plan-embalaje')));
    await t.pumpAndSettle();
    expect(find.textContaining('Estuche rígido con espuma a medida'), findsOneWidget);
  });

  testWidgets('comprar: correo, ubicación elegida, tarjeta de prueba, folio y aviso del correo', (t) async {
    final f = await _abrir(t);
    await _iniciarSesion(t);
    await _abrirProducto(t);
    await _elegirMonterrey(t);
    await t.tap(find.byKey(const Key('comprar-ahora')));
    await t.pumpAndSettle();

    // sin datos todavía no se puede pagar
    expect(t.widget<FilledButton>(find.byKey(const Key('confirmar-compra'))).onPressed, isNull);
    await t.enterText(find.byKey(const Key('nombre')), 'Diego');
    await t.ensureVisible(find.byKey(const Key('rellenar-prueba')));
    await t.tap(find.byKey(const Key('rellenar-prueba')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('confirmar-compra')));
    await t.tap(find.byKey(const Key('confirmar-compra')));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('folio')), findsOneWidget);
    expect(find.textContaining('MUS-2026-000007', findRichText: true), findsOneWidget);
    expect(find.textContaining('VISA •••• 4242'), findsOneWidget);
    expect(find.byKey(const Key('estado-correo')), findsOneWidget);
    expect(find.textContaining('diego@ejemplo.com'), findsWidgets);
    final enviado = f.cuerpos.last;
    expect(enviado['correo'], 'diego@ejemplo.com');
    expect((enviado['tarjeta'] as Map)['numero'], '4242 4242 4242 4242');
  });

  testWidgets('pago rechazado muestra el motivo y no cambia de pantalla', (t) async {
    await _abrir(t);
    await _iniciarSesion(t);
    await _abrirProducto(t);
    await _elegirMonterrey(t);
    await t.tap(find.byKey(const Key('comprar-ahora')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('nombre')), 'Diego');
    await t.enterText(find.byKey(const Key('tarjeta-numero')), '4000000000000002');
    await t.enterText(find.byKey(const Key('tarjeta-titular')), 'DIEGO RIVERA');
    await t.enterText(find.byKey(const Key('tarjeta-vence')), '1230');
    await t.enterText(find.byKey(const Key('tarjeta-cvv')), '123');
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('confirmar-compra')));
    await t.tap(find.byKey(const Key('confirmar-compra')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error-compra')), findsOneWidget);
    expect(find.textContaining('Tu banco rechazó la tarjeta'), findsOneWidget);
    expect(find.byKey(const Key('folio')), findsNothing);
  });

  testWidgets('sin sesión no se puede pagar: pide iniciar sesión', (t) async {
    await _abrir(t);
    await _abrirProducto(t);
    await _elegirMonterrey(t);
    await t.tap(find.byKey(const Key('comprar-ahora')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('login-para-pagar')), findsOneWidget);
    expect(t.widget<FilledButton>(find.byKey(const Key('confirmar-compra'))).onPressed, isNull);
  });

  testWidgets('login: contraseña incorrecta muestra el error; correcta abre el menú de cuenta y se puede cerrar sesión', (t) async {
    await _abrir(t);
    await _iniciarSesion(t, clave: 'Mala12345');
    expect(find.byKey(const Key('error-login')), findsOneWidget);
    await t.enterText(find.byKey(const Key('login-clave')), 'Clave1234');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('login-enviar')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-cuenta')), findsOneWidget);
    await t.tap(find.byKey(const Key('menu-cuenta')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('cerrar-sesion')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ingresar')), findsOneWidget);
  });

  testWidgets('usar mi ubicación: se convierte en destino y cotiza el envío', (t) async {
    final f = await _abrir(t);
    await _abrirProducto(t);
    await t.tap(find.byKey(const Key('usar-ubicacion')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ubicacion-activa')), findsOneWidget);
    expect(find.textContaining('cerca de Morelia'), findsOneWidget);
    expect(find.text('Embalaje Premium'), findsOneWidget);
    final envio = f.cuerpos.lastWhere((c) => c.containsKey('producto_id'));
    expect(envio['destino'], 'ubicacion');
    expect(envio['lat'], 19.7);
  });

  testWidgets('ubicación sin permiso: avisa y deja elegir ciudad', (t) async {
    await _abrir(t, ubicacionFalla: true);
    await _abrirProducto(t);
    await t.tap(find.byKey(const Key('usar-ubicacion')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('error-ubicacion')), findsOneWidget);
    expect(find.byKey(const Key('destino')), findsOneWidget); // sigue pudiendo elegir una ciudad
  });

  testWidgets('chat: responde, manda sesión, muestra productos, califica y remite al recomendador', (t) async {
    final f = await _abrir(t);
    await t.tap(find.byKey(const Key('abrir-chat')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('mensaje')), '¿qué ofertas tienen?');
    await t.tap(find.byKey(const Key('enviar')));
    await t.pumpAndSettle();
    expect(find.text('Estas son las mejores ofertas:'), findsOneWidget);
    expect(find.text('Guitarra eléctrica Gibson Les Paul'), findsWidgets);
    expect((f.cuerpos.last['sesion'] as String), startsWith('s'));

    await t.tap(find.byKey(const Key('util')));
    await t.pumpAndSettle();
    expect(f.cuerpos.last, {'consulta_id': 4, 'valor': 1});

    await t.enterText(find.byKey(const Key('mensaje')), '¿qué embalaje necesita?');
    await t.tap(find.byKey(const Key('enviar')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('abrir-recomendador')));
    await t.pumpAndSettle();
    expect(find.text('Datos del envío'), findsOneWidget);
  });

  testWidgets('recomendador de embalaje (bodega): campos del modelo, validación, corrección y folio', (t) async {
    final f = await _abrir(t);
    expect(find.text('Cotizador de envío'), findsNothing); // ya no está en el menú del comprador
    await t.ensureVisible(find.byKey(const Key('herramienta-recomendador')));
    await t.tap(find.byKey(const Key('herramienta-recomendador')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('explicacion-recomendador')), findsOneWidget); // explica para qué sirve
    expect(find.byKey(const Key('humedad')), findsOneWidget); // campos nuevos del modelo
    await t.tap(find.byKey(const Key('calcular')));
    await t.pumpAndSettle();
    expect(find.text('Escribe un número'), findsWidgets);

    await t.enterText(find.byKey(const Key('valor')), '15200');
    await t.enterText(find.byKey(const Key('peso')), '2.6');
    await t.enterText(find.byKey(const Key('dimension')), '105');
    await t.enterText(find.byKey(const Key('distancia')), '40');
    await t.tap(find.byKey(const Key('calcular')));
    await t.pumpAndSettle();
    expect(find.text('Recomendación: PREMIUM'), findsOneWidget);
    expect(f.cuerpos.last['humedad_destino'], 'media');
    expect(find.byKey(const Key('correccion')), findsOneWidget);

    await t.tap(find.byKey(const Key('confirmar')));
    await t.pumpAndSettle();
    expect(find.textContaining('MUS-2026-000009', findRichText: true), findsOneWidget);
  });
}
