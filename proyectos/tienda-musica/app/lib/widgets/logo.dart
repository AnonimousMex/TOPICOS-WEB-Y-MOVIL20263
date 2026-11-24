import 'package:flutter/material.dart';

import '../theme.dart';

const nombreTienda = 'Tesitura';

/// Logo de Tesitura. Es una imagen ya generada (assets/logo/tesitura_256.png, mismo diseño que tesitura.svg):
/// antes se dibujaba en código con desenfoque, y la web de Flutter recalcula ese desenfoque en cada cuadro.
class LogoTesitura extends StatelessWidget {
  const LogoTesitura({super.key, this.tam = 44, this.opacidad = 1});
  final double tam;
  final double opacidad;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/logo/tesitura_256.png',
        width: tam,
        height: tam,
        filterQuality: FilterQuality.medium,
        color: opacidad >= 1 ? null : Color.fromRGBO(255, 255, 255, opacidad),
        colorBlendMode: BlendMode.modulate, // atenúa sin crear una capa de transparencia extra
      );
}

/// Logo + nombre, para el encabezado y el pie.
class MarcaTesitura extends StatelessWidget {
  const MarcaTesitura({super.key, this.tam = 40, this.claro = true});
  final double tam;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final texto = claro ? Colors.white : tinta;
    // FittedBox: en celulares estrechos el nombre se reduce un poco en lugar de desbordarse.
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(mainAxisSize: MainAxisSize.min, children: [
      LogoTesitura(tam: tam),
      SizedBox(width: tam * 0.28),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(nombreTienda.toUpperCase(), style: TextStyle(fontSize: tam * 0.5, fontWeight: FontWeight.w800, letterSpacing: tam * 0.09, color: texto, height: 1.05)),
        Text('MÚSICA E INSTRUMENTOS', style: TextStyle(fontSize: tam * 0.2, fontWeight: FontWeight.w600, letterSpacing: tam * 0.05, color: doomBrillo, height: 1.2)),
      ]),
    ]));
  }
}
