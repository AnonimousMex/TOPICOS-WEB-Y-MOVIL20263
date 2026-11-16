import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const _suaveActivo = bool.fromEnvironment('SCROLL_SUAVE', defaultValue: true);
bool get _escritorioWeb => _suaveActivo && kIsWeb && const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

/// Desplazamiento suave con rueda/trackpad en la web de escritorio.
///
/// Flutter web mueve la página a saltos con cada «tic» de la rueda del mouse; aquí cada movimiento se anima
/// (200 ms, curva de salida suave), se amplifica y acelera al girar seguido, como en un navegador normal.
/// En móvil y en apps nativas se usa el desplazamiento nativo sin cambios. Las listas internas (chat,
/// filtros) siguen ganando el evento cuando pueden desplazarse, porque se registran antes.
class DesplazamientoSuave extends StatefulWidget {
  const DesplazamientoSuave({super.key, required this.builder});
  final Widget Function(BuildContext context, ScrollController controller, ScrollPhysics? fisica) builder;

  @override
  State<DesplazamientoSuave> createState() => _EstadoDesplazamiento();
}

class _EstadoDesplazamiento extends State<DesplazamientoSuave> {
  final _controller = ScrollController();
  double _objetivo = 0;
  int _racha = 0;
  DateTime _ultimo = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rueda(PointerSignalEvent evento) {
    if (evento is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(evento, (e) {
      final dy = (e as PointerScrollEvent).scrollDelta.dy;
      if (!_controller.hasClients || dy == 0) return;
      final pos = _controller.position;
      // Trackpad: deltas pequeños y continuos (ya traen su propia inercia): se aplican directo, sin retraso.
      if (dy.abs() < 40) {
        _controller.jumpTo((pos.pixels + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent));
        _ultimo = DateTime.fromMillisecondsSinceEpoch(0);
        return;
      }
      // Rueda de mouse: un «tic» (~100 px) es muy poco para tarjetas de ~420 px. Se amplifica y acelera si sigues girando.
      final ahora = DateTime.now();
      final enCurso = ahora.difference(_ultimo).inMilliseconds < 260;
      _racha = enCurso ? _racha + 1 : 1;
      final factor = (2.0 + 0.45 * (_racha - 1)).clamp(2.0, 5.0);
      _objetivo = ((enCurso ? _objetivo : pos.pixels) + dy * factor).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      _ultimo = ahora;
      _controller.animateTo(_objetivo, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_escritorioWeb) return widget.builder(context, _controller, null);
    return Listener(onPointerSignal: _rueda, child: widget.builder(context, _controller, const NeverScrollableScrollPhysics()));
  }
}

/// Lista vertical de página con desplazamiento suave.
class ListaSuave extends StatelessWidget {
  const ListaSuave({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => DesplazamientoSuave(builder: (_, c, f) => ListView(controller: c, physics: f, padding: padding, children: children));
}
