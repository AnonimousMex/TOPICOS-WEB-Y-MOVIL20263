import 'package:flutter/material.dart';

import '../theme.dart';


class Centrado extends StatelessWidget {
  const Centrado({super.key, required this.child, this.ancho = 1200});
  final Widget child;
  final double ancho;

  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: ancho), child: child));
}

class Seccion extends StatelessWidget {
  const Seccion({super.key, required this.titulo, required this.child, this.accion, this.alAccion});
  final String titulo;
  final Widget child;
  final String? accion;
  final VoidCallback? alAccion;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(8), border: Border.all(color: bordeSutil)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 20, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: doomClaro, borderRadius: BorderRadius.circular(2))),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
            if (accion != null) TextButton(onPressed: alAccion, child: Text(accion!)),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class ErrorConReintento extends StatelessWidget {
  const ErrorConReintento({super.key, required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: gris),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(160, 46)), onPressed: onReintentar, child: const Text('Reintentar')),
        ]),
      );
}

class Insignia extends StatelessWidget {
  const Insignia(this.texto, this.color, {super.key});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
        child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

const alturaTarjeta = 410.0;
