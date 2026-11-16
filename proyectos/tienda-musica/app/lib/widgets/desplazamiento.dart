import 'package:flutter/material.dart';

/// Conserva el controlador de la página y deja los gestos a Scrollable.
/// No amplifica deltas ni reinicia animaciones al recibir eventos del trackpad.
class DesplazamientoSuave extends StatefulWidget {
  const DesplazamientoSuave({super.key, required this.builder});
  final Widget Function(BuildContext context, ScrollController controller, ScrollPhysics? fisica) builder;

  @override
  State<DesplazamientoSuave> createState() => _EstadoDesplazamiento();
}

class _EstadoDesplazamiento extends State<DesplazamientoSuave> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller, null);
}

/// Lista vertical que construye los elementos próximos al área visible.
class ListaSuave extends StatelessWidget {
  const ListaSuave({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => DesplazamientoSuave(builder: (_, c, f) => ListView(controller: c, physics: f, padding: padding, children: children));
}
