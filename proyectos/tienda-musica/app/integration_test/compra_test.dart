import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tienda_musica/api.dart';
import 'package:tienda_musica/main.dart';
import 'package:tienda_musica/state.dart';
import 'package:tienda_musica/widgets/chat_panel.dart';
import 'package:tienda_musica/widgets/producto_card.dart';

/// Recorrido completo con sesión contra el backend real: registro (con contraseña débil rechazada),
/// embalaje por ciudad, pago con tarjeta de prueba, folio, Mis compras y chat con permisos.
/// Se ejecuta en Android con: flutter drive --driver=test_driver/entrega_driver.dart --target=integration_test/compra_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Tesitura: registro, compra con folio, Mis compras y chat con sesión', (tester) async {
    final api = RumboApi();
    await tester.pumpWidget(TiendaApp(api: api));
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }

    Future<void> until(bool Function() ready, {int segundos = 50}) async {
      final fin = DateTime.now().add(Duration(seconds: segundos));
      while (!ready() && DateTime.now().isBefore(fin)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(ready(), isTrue, reason: 'No llegó la pantalla o respuesta esperada');
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> tap(Finder f) async {
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(f, 220, scrollable: find.byType(Scrollable).last, maxScrolls: 25);
      }
      await tester.ensureVisible(f.last);
      await tester.pump(const Duration(milliseconds: 900)); // termina el desplazamiento antes de tocar
      await tester.tap(f.last);
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> escribir(String clave, String texto) async {
      final f = find.byKey(Key(clave));
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(f, 220, scrollable: find.byType(Scrollable).last, maxScrolls: 25);
      }
      await tester.ensureVisible(f);
      await tester.enterText(f, texto);
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> foto(String nombre) async {
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot(nombre);
    }

    final correo = 'android.${DateTime.now().millisecondsSinceEpoch}@ejemplo.com';
    final pasos = <String, Object>{};

    // 1) catálogo cargado desde el servidor
    await until(() => find.byType(CircularProgressIndicator).evaluate().isEmpty);
    await foto('01_catalogo');
    pasos['catalogo'] = 'ok';

    // 2) registro: la contraseña débil se rechaza y luego se crea la cuenta
    await tap(find.byKey(const Key('ingresar')));
    await until(() => find.byKey(const Key('login-cambiar')).evaluate().isNotEmpty);
    await foto('02_login');
    await tap(find.byKey(const Key('login-cambiar')));
    await escribir('login-nombre', 'Prueba Android');
    await escribir('login-correo', correo);
    await escribir('login-clave', 'clave1234');
    FocusManager.instance.primaryFocus?.unfocus();
    await tap(find.byKey(const Key('login-enviar')));
    await until(() => find.text('Usa mayúscula, minúscula y número.').evaluate().isNotEmpty);
    await foto('03_clave_debil');
    pasos['clave_debil_rechazada'] = true;
    // En Android un segundo enterText sobre el mismo campo no reemplaza el texto; se escribe en el controlador.
    tester.widget<TextField>(find.byKey(const Key('login-clave'))).controller!.text = 'Clave1234';
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    final textoClave = tester.widget<TextField>(find.byKey(const Key('login-clave'))).controller!.text;
    expect(textoClave, 'Clave1234', reason: 'El campo debe tener la contraseña nueva antes de enviar');
    await tap(find.byKey(const Key('login-enviar')));
    await tester.pump(const Duration(seconds: 3));
    await foto('03b_tras_registrar');
    await until(() => find.byKey(const Key('menu-cuenta')).evaluate().isNotEmpty);
    await foto('04_sesion');
    pasos['registro'] = correo;

    // 3) producto, ciudad y embalaje recomendado por el servidor
    final productos = await api.productos(const Filtro(q: 'Stratocaster'));
    expect(productos, isNotEmpty);
    final producto = productos.first;
    await escribir('busqueda', producto.nombre);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    final tarjeta = find.descendant(of: find.byType(ProductoCard), matching: find.text(producto.nombre));
    await until(() => tarjeta.evaluate().isNotEmpty);
    await tap(tarjeta);
    await until(() => find.byKey(const Key('titulo')).evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 2)); // la lista de ciudades llega del servidor
    await tap(find.byKey(const Key('destino')));
    await tester.pump(const Duration(seconds: 1));
    await foto('05a_destino');
    await until(() => find.text('Monterrey · 900 km').evaluate().isNotEmpty, segundos: 10);
    await tester.tap(find.text('Monterrey · 900 km').last);
    await tester.pump(const Duration(milliseconds: 800));
    await until(() => find.byKey(const Key('resultado-envio')).evaluate().isNotEmpty);
    await foto('05_embalaje');
    pasos['embalaje'] = 'ok';

    // 4) carrito, tarjeta de prueba y folio
    await tap(find.byKey(const Key('comprar-ahora')));
    await until(() => find.byKey(const Key('confirmar-compra')).evaluate().isNotEmpty);
    await escribir('nombre', 'Prueba Android');
    await tap(find.byKey(const Key('rellenar-prueba')));
    FocusManager.instance.primaryFocus?.unfocus();
    await foto('06_pago');
    await tap(find.byKey(const Key('confirmar-compra')));
    await until(() => find.byKey(const Key('folio')).evaluate().isNotEmpty);
    final folio = tester.widget<SelectableText>(find.byKey(const Key('folio'))).data!;
    expect(folio, matches(RegExp(r'^MUS-\d{4}-\d{6}$')));
    await foto('07_folio');
    pasos['folio'] = folio;

    // 5) Mis compras (el servidor filtra por la cuenta) y el folio existe
    final tienda = TiendaScope.leer(tester.element(find.byKey(const Key('folio'))));
    final compras = await api.misCompras();
    expect(compras.expand((c) => c.pedidos).map((p) => p.folio), contains(folio));
    pasos['mis_compras'] = compras.length;

    // 6) chat: con sesión puede consultar SU folio
    final ctx = tester.element(find.byKey(const Key('folio')));
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const ChatPage()));
    await tester.pumpAndSettle();
    await until(() => find.byKey(const Key('mensaje')).evaluate().isNotEmpty);
    final antes = tienda.chat.length;
    tester.widget<TextField>(find.byKey(const Key('mensaje'))).controller!.text = '¿Cómo va mi pedido $folio?';
    await tester.pump();
    await tap(find.byKey(const Key('enviar')));
    await until(() => !tienda.chatEnviando && tienda.chat.length >= antes + 2);
    expect(tienda.chat.last.respuesta!.intencion, 'consulta_folio');
    expect(tienda.chat.last.texto, contains(folio));
    await foto('08_chat_folio');
    pasos['chat_folio'] = tienda.chat.last.texto;

    // 7) sin sesión, el checkout responde 401 (el servidor decide, no la app)
    await tienda.cerrarSesion();
    var rechazado = false;
    try {
      await api.comprar(
        cliente: 'X',
        correo: 'x@ejemplo.com',
        destino: DestinoElegido.ciudad('Monterrey'),
        tarjeta: const Tarjeta(numero: '4242 4242 4242 4242', titular: 'X', vencimiento: '12/30', cvv: '123'),
        lineas: [(productoId: producto.id, cantidad: 1)],
      );
    } on ApiException catch (e) {
      rechazado = e.status == 401;
    }
    expect(rechazado, isTrue, reason: 'Sin sesión el servidor debe responder 401');
    pasos['sin_sesion_401'] = true;

    binding.reportData = {...?binding.reportData, 'api': api.baseUrl, 'pasos': pasos, 'plataforma': kIsWeb ? 'web' : 'android'};
  }, timeout: const Timeout(Duration(minutes: 10)));
}
