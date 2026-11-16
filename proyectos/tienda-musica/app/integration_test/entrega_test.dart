import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:tienda_musica/main.dart';
import 'package:tienda_musica/api.dart';
import 'package:tienda_musica/state.dart';
import 'package:tienda_musica/pages/recomendar_page.dart';
import 'package:tienda_musica/widgets/chat_panel.dart';
import 'package:tienda_musica/widgets/producto_card.dart';

class RegistroHttp extends http.BaseClient {
  final inner = http.Client();
  final respuestas = <Map<String, dynamic>>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await http.Response.fromStream(await inner.send(request));
    if (request.method == 'POST') {
      respuestas.add({'ruta': request.url.path, 'http': response.statusCode, 'respuesta': jsonDecode(response.body)});
    }
    return http.StreamedResponse(Stream.value(response.bodyBytes), response.statusCode, headers: response.headers, request: request);
  }
  @override
  void close() { inner.close(); super.close(); }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Tesitura: catálogo, reglas, folio y asistente', (tester) async {
    final trace = RegistroHttp();
    final api = RumboApi(cliente: trace);
    const folioCompartido = String.fromEnvironment('FOLIO_COMPARTIDO');
    Map<String, dynamic>? pedidoCompartido;
    if (folioCompartido.isNotEmpty) {
      final consulta = await http.get(Uri.parse('${api.baseUrl}/pedidos/$folioCompartido/'));
      expect(consulta.statusCode, 200, reason: 'Android debe encontrar el pedido creado desde la web');
      pedidoCompartido = jsonDecode(consulta.body) as Map<String, dynamic>;
      expect(pedidoCompartido['folio'], folioCompartido);
    }
    await tester.pumpWidget(TiendaApp(api: api));
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    Future<void> until(bool Function() ready) async {
      final end = DateTime.now().add(const Duration(seconds: 50));
      while (!ready() && DateTime.now().isBefore(end)) { await tester.pump(const Duration(milliseconds: 250)); }
      expect(ready(), isTrue, reason: 'No llegó la respuesta o pantalla esperada');
      await tester.pump(const Duration(milliseconds: 350));
    }
    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 220, scrollable: find.byType(Scrollable).last, maxScrolls: 20);
      }
      await tester.ensureVisible(finder.last);
      await tester.tap(finder.last);
      await tester.pump(const Duration(milliseconds: 350));
    }
    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot(name);
    }
    await until(() => find.byType(CircularProgressIndicator).evaluate().isEmpty);
    await shot('01_catalogo');
    final productos = await api.productos(const Filtro(q: 'Stratocaster'));
    expect(productos, isNotEmpty);
    final producto = productos.first;
    await tester.enterText(find.byKey(const Key('busqueda')), producto.nombre);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    final tarjeta = find.descendant(of: find.byType(ProductoCard), matching: find.text(producto.nombre));
    await until(() => tarjeta.evaluate().isNotEmpty);
    await tap(tarjeta);
    await until(() => find.byKey(const Key('titulo')).evaluate().isNotEmpty);
    await shot('02_producto');
    final context = tester.element(find.byKey(const Key('titulo')));
    final tienda = TiendaScope.leer(context);
    // Se comprueba el formulario de producción con un caso reproducible de reglas.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecomendarPage(api: api)));
    await tester.pumpAndSettle();
    for (final item in {'valor': '9000', 'peso': '3', 'dimension': '105', 'distancia': '520'}.entries) {
      if (find.byKey(Key(item.key)).evaluate().isEmpty) {
        await tester.scrollUntilVisible(find.byKey(Key(item.key)), 220, scrollable: find.byType(Scrollable).last, maxScrolls: 20);
      }
      await tester.ensureVisible(find.byKey(Key(item.key)));
      await tester.enterText(find.byKey(Key(item.key)), item.value);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.ensureVisible(find.byKey(const Key('valor')));
    await shot('03_entradas');
    for (final key in ['humedad', 'zona']) {
      await tap(find.byKey(Key(key)));
      await tap(find.text('Alta'));
    }
    await shot('04_condiciones');
    await tap(find.byKey(const Key('calcular')));
    await until(() => find.byKey(const Key('nivel-final')).evaluate().isNotEmpty);
    final recomendacion = trace.respuestas.last['respuesta'] as Map<String, dynamic>;
    expect(recomendacion['corregido_por_reglas'], isTrue);
    expect(recomendacion['nivel_final'], 'premium');
    await tester.ensureVisible(find.byKey(const Key('nivel-final')));
    await shot('05_recomendacion');
    await tester.ensureVisible(find.byKey(const Key('correccion')));
    await shot('06_reglas');
    await tap(find.byKey(const Key('confirmar')));
    await until(() => find.byKey(const Key('folio')).evaluate().isNotEmpty);
    final folio = tester.widget<SelectableText>(find.byKey(const Key('folio'))).data!;
    expect(folio, matches(RegExp(r'^MUS-\d{4}-\d{6}$')));
    await shot('07_folio');
    final pageContext = tester.element(find.byKey(const Key('folio')));
    Navigator.of(pageContext).push(MaterialPageRoute(builder: (_) => const ChatPage()));
    await tester.pumpAndSettle();
    await until(() => find.byKey(const Key('mensaje')).evaluate().isNotEmpty);
    Future<void> chat(String question, Set<String> intents, String screenshot) async {
      final before = tienda.chat.length;
      final control = tester.widget<TextField>(find.byKey(const Key('mensaje'))).controller!;
      control.text = question;
      await tester.pump();
      await tap(find.byKey(const Key('enviar')));
      await until(() => !tienda.chatEnviando && tienda.chat.length >= before + 2);
      expect(tienda.chat.last.respuesta, isNotNull);
      expect(intents, contains(tienda.chat.last.respuesta!.intencion));
      await shot(screenshot);
    }
    await chat('hola, buenas tardes', {'saludo'}, '08_chat_saludo');
    final folioConsultado = folioCompartido.isEmpty ? folio : folioCompartido;
    await chat('¿Cómo va mi pedido $folioConsultado?', {'consulta_folio'}, '09_chat_folio');
    expect(tienda.chat.last.texto, contains(folioConsultado));
    await chat('¿qué embalaje necesita mi violín?', {'pedir_recomendacion'}, '10_chat_dominio');
    await chat('cuéntame un chiste', {'fuera_dominio', 'no_entendido'}, '11_chat_fuera_dominio');
    binding.reportData = {...?binding.reportData, 'folio': folio, 'folio_consultado': folioConsultado, 'pedido_creado_en_web': pedidoCompartido, 'api': api.baseUrl, 'plataforma': kIsWeb ? 'web' : 'android', 'recomendacion': recomendacion, 'peticiones': trace.respuestas};
    trace.close();
  }, timeout: const Timeout(Duration(minutes: 8)));
}
