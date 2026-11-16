import 'package:flutter/material.dart';

import '../api.dart';

/// Decodifica las miniaturas ANTES de que lleguen a la pantalla, poco a poco (3 cada 90 ms) para no bloquear nada.
/// Así, al desplazarte, las fotos ya están listas y no hay tirones por decodificar justo cuando aparecen.
Future<void> precargarFotos(BuildContext context, Iterable<Producto> productos, {int maximo = 60}) async {
  final urls = [for (final p in productos) p.imagenMini ?? p.imagenUrl].whereType<String>().toSet().take(maximo).toList();
  for (var i = 0; i < urls.length; i += 3) {
    if (!context.mounted) return;
    for (final u in urls.skip(i).take(3)) {
      precacheImage(NetworkImage(u), context, onError: (_, _) {});
    }
    await Future.delayed(const Duration(milliseconds: 90));
  }
}
