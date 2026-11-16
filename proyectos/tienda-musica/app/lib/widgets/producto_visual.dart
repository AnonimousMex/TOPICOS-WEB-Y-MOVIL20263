import 'package:flutter/material.dart';

import '../theme.dart';

/// Foto del producto. Con `imagenUrl` se muestra la foto (fondo blanco, sin recortar el instrumento);
/// mientras carga, o si no hay foto o falla, se usa un visual con el ícono del tipo y la marca.
class ProductoVisual extends StatelessWidget {
  const ProductoVisual({super.key, required this.categoria, required this.marca, this.imagenUrl, this.alto = 170, this.compacto = false});
  final String categoria, marca;
  final String? imagenUrl;
  final double alto;
  final bool compacto;

  Widget _generado(BuildContext context) {
    final cat = categoriaDe(categoria);
    return Container(
      height: alto,
      width: double.infinity,
      decoration: BoxDecoration(gradient: RadialGradient(colors: [Color.alphaBlend(cat.color.withValues(alpha: 0.30), const Color(0xFF1C252A)), const Color(0xFF0C1114)], radius: 0.95, center: const Alignment(0, -0.2))),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(right: -alto * 0.12, bottom: -alto * 0.14, child: Icon(cat.icono, size: alto * 0.78, color: cat.color.withValues(alpha: 0.12))),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(cat.icono, size: alto * 0.42, color: cat.color),
          if (!compacto) ...[
            SizedBox(height: alto * 0.05),
            Text(marca.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: cat.color.withValues(alpha: 0.85))),
          ],
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imagenUrl == null) return _generado(context);
    return Container(
      height: alto,
      width: double.infinity,
      color: const Color(0xFFF1F4F3),
      padding: EdgeInsets.all(compacto ? 2 : 6),
      child: Image.network(
        imagenUrl!,
        fit: BoxFit.contain,
        // Las tarjetas usan miniaturas (ya pequeñas): sin fundido por imagen ni reescalado, que es lo que hacía lento el desplazamiento.
        // La foto grande de la ficha sí aparece con un fundido suave.
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        frameBuilder: alto < 250 ? null : (ctx, hijo, frame, sincrona) => sincrona ? hijo : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: Anim.normal, curve: Anim.curva, child: hijo),
        errorBuilder: (ctx, _, _) => _generado(ctx),
      ),
    );
  }
}

class Estrellas extends StatelessWidget {
  const Estrellas(this.rating, {super.key, this.tam = 14});
  final double rating;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++) Icon(rating >= i ? Icons.star_rounded : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded), size: tam, color: doom),
    ]);
  }
}

/// Logo de la marca sobre un chip blanco (los logos están hechos para fondo claro); si no hay logo libre se dibuja el nombre.
class MarcaLogo extends StatelessWidget {
  const MarcaLogo({super.key, required this.nombre, this.logoUrl, this.alto = 30, this.ancho = 110});
  final String nombre;
  final String? logoUrl;
  final double alto, ancho;

  Widget _texto() => Text(nombre.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12, color: Color(0xFF1D2427)));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
      child: logoUrl == null ? Center(child: _texto()) : Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Center(child: _texto())),
    );
  }
}
