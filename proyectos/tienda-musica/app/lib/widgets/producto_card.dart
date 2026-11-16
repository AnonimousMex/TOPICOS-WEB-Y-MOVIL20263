import 'package:flutter/material.dart';

import '../api.dart';
import '../pages/producto_page.dart';
import '../state.dart';
import '../theme.dart';
import 'producto_visual.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({super.key, required this.producto});
  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final tienda = TiendaScope.leer(context);
    final cuota = p.precio / 12;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(10), border: Border.all(color: bordeSutil)),
        // El resaltado al pasar el mouse lo da el InkWell (sin reconstruir nada): antes cada tarjeta que pasaba bajo el cursor al desplazar reconstruía y animaba.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              hoverColor: doomBrillo.withValues(alpha: 0.07),
              key: Key('producto-${p.id}'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoPage(producto: p))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  ProductoVisual(categoria: p.categoria, marca: p.marca, imagenUrl: p.imagenMini ?? p.imagenUrl, alto: 168),
                  if (p.descuento > 0) Positioned(left: 8, top: 8, child: _Etiqueta('${p.descuento}% OFF', verde)),
                  if (p.agotado) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.55), alignment: Alignment.center, child: const _Etiqueta('AGOTADO', gris))),
                ]),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 36, child: Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.25))),
                    const SizedBox(height: 6),
                    SizedBox(height: 16, child: p.precioOriginal != null ? Text(dinero(p.precioOriginal!), style: const TextStyle(fontSize: 12, color: grisClaro, decoration: TextDecoration.lineThrough)) : null),
                    Text(dinero(p.precio), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: tinta)),
                    Text('en 12x ${dinero(cuota)} sin interés', style: const TextStyle(fontSize: 12, color: verde)),
                    const SizedBox(height: 4),
                    SizedBox(height: 16, child: p.envioGratis ? const Text('Envío gratis', style: TextStyle(fontSize: 12, color: verde, fontWeight: FontWeight.w700)) : null),
                    const SizedBox(height: 4),
                    Row(children: [Estrellas(p.rating, tam: 13), const SizedBox(width: 4), Text('${p.rating}', style: const TextStyle(fontSize: 12, color: grisClaro))]),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10)),
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('Añadir', style: TextStyle(fontSize: 13)),
                        onPressed: p.agotado
                            ? null
                            : () {
                                tienda.agregar(p);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agregado al carrito: ${p.nombre}'), duration: const Duration(seconds: 2)));
                              },
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, this.color);
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

/// Carrusel horizontal de tarjetas.
class FilaProductos extends StatelessWidget {
  const FilaProductos({super.key, required this.productos});
  final List<Producto> productos;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Sin productos.'));
    return SizedBox(
      height: 410,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: productos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 224, child: ProductoCard(producto: productos[i])),
      ),
    );
  }
}
