import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_musica/widgets/desplazamiento.dart';

void main() {
  testWidgets('rueda y trackpad conservan la distancia sin acelerar ni animar eventos', (t) async {
    late ScrollController controller;
    await t.pumpWidget(MaterialApp(
      home: DesplazamientoSuave(builder: (_, c, fisica) {
        controller = c;
        return ListView.builder(
          controller: c,
          physics: fisica,
          itemExtent: 100,
          itemCount: 100,
          itemBuilder: (_, i) => Text('Elemento $i'),
        );
      }),
    ));

    var esperado = 0.0;
    for (final delta in [8.0, 48.0, 12.0, 100.0, -45.0]) {
      await t.sendEventToBinding(PointerScrollEvent(
        position: t.getCenter(find.byType(ListView)),
        scrollDelta: Offset(0, delta),
        kind: PointerDeviceKind.mouse,
      ));
      await t.pump();
      esperado += delta;
      expect(controller.offset, closeTo(esperado, 0.01));
      expect(controller.position.isScrollingNotifier.value, isFalse);
    }
  });

  testWidgets('la página admite arrastre táctil y desplazamiento en ambos sentidos', (t) async {
    await t.pumpWidget(MaterialApp(
      home: ListaSuave(children: [
        for (var i = 0; i < 30; i++) SizedBox(height: 100, child: Text('Elemento $i')),
      ]),
    ));
    final scroll = t.state<ScrollableState>(find.byType(Scrollable));
    await t.drag(find.byType(ListView), const Offset(0, -300));
    await t.pumpAndSettle();
    final despues = scroll.position.pixels;
    expect(despues, greaterThan(0));
    await t.drag(find.byType(ListView), const Offset(0, 150));
    await t.pumpAndSettle();
    expect(scroll.position.pixels, lessThan(despues));
  });
}
