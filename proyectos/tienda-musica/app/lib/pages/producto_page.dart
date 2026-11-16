import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/marco.dart';
import '../widgets/producto_card.dart';
import '../widgets/producto_visual.dart';
import '../widgets/selector_destino.dart';
import 'carrito_page.dart';

class ProductoPage extends StatefulWidget {
  const ProductoPage({super.key, required this.producto});
  final Producto producto;

  @override
  State<ProductoPage> createState() => _ProductoPageState();
}

class _ProductoPageState extends State<ProductoPage> {
  late Producto _p = widget.producto;
  List<Destino> _destinos = [];
  int _cantidad = 1;
  Recomendacion? _envio;
  bool _cotizando = false;
  String? _errorEnvio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final api = TiendaScope.leer(context).api;
    try {
      final r = await Future.wait([api.producto(widget.producto.id), api.destinos()]);
      if (!mounted) return;
      setState(() {
        _p = r[0] as Producto;
        _destinos = r[1] as List<Destino>;
      });
      if (TiendaScope.leer(context).destino != null) _cotizar(); // ya elegiste destino en otra pantalla
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorEnvio = e.mensaje);
    }
  }

  Future<void> _cotizar() async {
    final tienda = TiendaScope.leer(context);
    if (tienda.destino == null) return;
    final api = tienda.api;
    setState(() {
      _cotizando = true;
      _errorEnvio = null;
    });
    try {
      final r = await api.cotizarEnvio(_p.id, _cantidad, tienda.destino!);
      if (mounted) setState(() => _envio = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorEnvio = e.mensaje;
          _envio = null;
        });
      }
    } finally {
      if (mounted) setState(() => _cotizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final ancho = esAncho(context);
    final galeria = _Galeria(p: p);
    final info = _Info(p: p);
    final compra = _CajaCompra(
      p: p,
      destinos: _destinos,
      cantidad: _cantidad,
      envio: _envio,
      cotizando: _cotizando,
      error: _errorEnvio,
      onDestino: _cotizar,
      onCantidad: (v) {
        setState(() => _cantidad = v);
        _cotizar();
      },
    );
    return Marco(
      child: ListaSuave(children: [
        Centrado(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(8), border: Border.all(color: bordeSutil)),
                child: ancho
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 440, child: galeria),
                        const SizedBox(width: 24),
                        Expanded(child: info),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: compra),
                      ])
                    : Column(children: [galeria, const SizedBox(height: 16), info, const SizedBox(height: 16), compra]),
              ),
              const SizedBox(height: 16),
              if (p.similares.isNotEmpty) Seccion(titulo: 'Productos relacionados', child: FilaProductos(productos: p.similares)),
            ]),
          ),
        ),
        const PieDePagina(),
      ]),
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.p});
  final Producto p;

  @override
  Widget build(BuildContext context) {
    final aviso = switch (p.imagenNivel) {
      'marca' => 'Foto ilustrativa de ${p.marca}; puede ser otro modelo. ',
      'referencia' => 'Foto de referencia del tipo de instrumento (no es esta marca ni modelo). ',
      _ => '',
    };
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8), child: ProductoVisual(categoria: p.categoria, marca: p.marca, imagenUrl: p.imagenUrl, alto: 380)),
      if (p.imagenUrl != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$aviso${p.imagenCredito ?? ''} · Wikimedia Commons',
            key: const Key('credito-foto'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: grisClaro, height: 1.3),
          ),
        ),
      const SizedBox(height: 10),
      Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              decoration: BoxDecoration(border: Border.all(color: i == 0 ? doom : Colors.black.withValues(alpha: 0.12), width: i == 0 ? 2 : 1), borderRadius: BorderRadius.circular(6)),
              clipBehavior: Clip.antiAlias,
              child: ProductoVisual(categoria: p.categoria, marca: p.marca, alto: 62, compacto: true),
            ),
          ),
      ]),
    ]);
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.p});
  final Producto p;

  @override
  Widget build(BuildContext context) {
    final cat = categoriaDe(p.categoria);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Nuevo  |  +${p.vendidos} vendidos', style: const TextStyle(fontSize: 13, color: gris))), MarcaLogo(nombre: p.marca, logoUrl: p.marcaLogo, alto: 28, ancho: 90)]),
      const SizedBox(height: 8),
      Text(p.nombre, key: const Key('titulo'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25)),
      const SizedBox(height: 8),
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [Text('${p.rating}', style: const TextStyle(fontSize: 13, color: gris)), Estrellas(p.rating), Text('(${(p.vendidos * 0.22).round()} opiniones)', style: const TextStyle(fontSize: 13, color: doom))]),
      const SizedBox(height: 16),
      if (p.precioOriginal != null) Text(dinero(p.precioOriginal!), style: const TextStyle(fontSize: 15, color: grisClaro, decoration: TextDecoration.lineThrough)),
      Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 10, children: [
        Text(dinero(p.precio), key: const Key('precio'), style: const TextStyle(fontSize: 36, height: 1.1)),
        if (p.descuento > 0) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('${p.descuento}% OFF', style: const TextStyle(color: verde, fontSize: 16, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 4),
      Text('Mismo precio en 12 meses de ${dinero(p.precio / 12)}', style: const TextStyle(color: verde, fontSize: 14)),
      const SizedBox(height: 20),
      const Text('Lo que tienes que saber de este producto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      for (final d in [
        ('Marca', p.marca),
        ('Tipo', p.subcategoria.isEmpty ? cat.etiqueta : p.subcategoria),
        ('Peso', '${p.peso} kg'),
        ('Dimensión mayor', '${p.dimensionMax} cm'),
        ('Frágil', p.fragil ? 'Sí, requiere manejo cuidadoso' : 'No'),
      ])
        Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 140, child: Text(d.$1, style: const TextStyle(color: gris))), Expanded(child: Text(d.$2))])),
      const SizedBox(height: 16),
      Text(p.descripcion, style: const TextStyle(height: 1.45, color: gris)),
    ]);
  }
}

class _CajaCompra extends StatelessWidget {
  const _CajaCompra({required this.p, required this.destinos, required this.cantidad, required this.envio, required this.cotizando, required this.error, required this.onDestino, required this.onCantidad});
  final Producto p;
  final List<Destino> destinos;
  final int cantidad;
  final Recomendacion? envio;
  final bool cotizando;
  final String? error;
  final VoidCallback onDestino;
  final ValueChanged<int> onCantidad;

  @override
  Widget build(BuildContext context) {
    final tienda = TiendaScope.leer(context);
    final maximo = p.existencias.clamp(1, 10);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: bordeSutil), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.envioGratis) const Row(children: [Icon(Icons.local_shipping_outlined, color: verde, size: 20), SizedBox(width: 8), Expanded(child: Text('Envío gratis a todo el país', style: TextStyle(color: verde, fontWeight: FontWeight.w700)))]),
        const SizedBox(height: 10),
        Text(p.agotado ? 'Sin stock' : (p.existencias <= 5 ? '¡Últimas ${p.existencias} disponibles!' : 'Stock disponible'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.agotado ? Colors.red : tinta)),
        const SizedBox(height: 12),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Cantidad: ', style: TextStyle(color: gris)),
          DropdownButton<int>(
            key: const Key('cantidad'),
            value: cantidad.clamp(1, maximo),
            items: [for (var i = 1; i <= maximo; i++) DropdownMenuItem(value: i, child: Text('$i ${i == 1 ? 'unidad' : 'unidades'}'))],
            onChanged: p.agotado ? null : (v) => onCantidad(v!),
          ),
        ]),
        const SizedBox(height: 10),
        _EnvioProtegido(destinos: destinos, envio: envio, cotizando: cotizando, error: error, onDestino: onDestino),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('comprar-ahora'),
          onPressed: p.agotado
              ? null
              : () {
                  tienda.agregar(p, cantidad);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CarritoPage()));
                },
          child: const Text('Comprar ahora'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('agregar-carrito'),
          style: OutlinedButton.styleFrom(backgroundColor: doomSuave),
          onPressed: p.agotado
              ? null
              : () {
                  tienda.agregar(p, cantidad);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agregado al carrito: ${p.nombre}'), duration: const Duration(seconds: 2)));
                },
          child: const Text('Agregar al carrito'),
        ),
        const SizedBox(height: 14),
        const _Dato(Icons.storefront_outlined, 'Vendido por Tienda de Música'),
        const _Dato(Icons.replay_outlined, 'Devolución gratis (política simulada)'),
        const _Dato(Icons.verified_outlined, 'Garantía del fabricante'),
      ]),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Icon(icono, size: 17, color: gris), const SizedBox(width: 8), Expanded(child: Text(texto, style: const TextStyle(fontSize: 12.5, color: gris)))]));
}

/// Aquí vive el recomendador dentro de la tienda: según la ciudad elegida, el modelo + las reglas
/// deciden el embalaje y el seguro para ESTE producto.
class _EnvioProtegido extends StatelessWidget {
  const _EnvioProtegido({required this.destinos, required this.envio, required this.cotizando, required this.error, required this.onDestino});
  final List<Destino> destinos;
  final Recomendacion? envio;
  final bool cotizando;
  final String? error;
  final VoidCallback onDestino;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Anim.normal,
      curve: Anim.curva,
      alignment: Alignment.topCenter,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: doomSuave, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.shield_outlined, color: doom, size: 20), SizedBox(width: 8), Text('Envío protegido', style: TextStyle(fontWeight: FontWeight.w700))]),
        const SizedBox(height: 4),
        const Text('Elige tu ciudad (o usa tu ubicación) y te decimos con qué embalaje y seguro viaja.', style: TextStyle(fontSize: 12, color: gris)),
        const SizedBox(height: 8),
        SelectorDestino(destinos: destinos, onCambio: onDestino, etiqueta: 'Ciudad de entrega'),
        if (cotizando) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: doom)),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        AnimatedSwitcher(
          duration: Anim.normal,
          switchInCurve: Anim.curva,
          transitionBuilder: (hijo, anim) => FadeTransition(opacity: anim, child: hijo),
          child: (envio != null && !cotizando) ? _Resultado(key: ValueKey('${envio!.nivelFinal}-${envio!.costo}-${envio!.confianza}'), r: envio!) : const SizedBox(width: double.infinity, key: ValueKey('sin-resultado')),
        ),
      ]),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({super.key, required this.r});
  final Recomendacion r;

  @override
  Widget build(BuildContext context) {
    final n = nivelDe(r.nivelFinal);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        key: const Key('resultado-envio'),
        color: superficieAlta,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: n.color.withValues(alpha: 0.5))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(n.icono, color: n.color),
            const SizedBox(width: 8),
            Expanded(child: Text('Embalaje ${n.etiqueta}', key: const Key('nivel-envio'), style: TextStyle(fontWeight: FontWeight.w800, color: n.color, fontSize: 16))),
            Text(r.costo == 0 ? 'Incluido' : '+${dinero(r.costo)}', style: TextStyle(fontWeight: FontWeight.w700, color: r.costo == 0 ? verde : tinta)),
          ]),
          const SizedBox(height: 4),
          Text(r.descripcion ?? n.resumen, style: const TextStyle(fontSize: 12.5, color: gris, height: 1.3)),
          const SizedBox(height: 8),
          Text(r.razon ?? 'El modelo sugirió «${nivelDe(r.nivelModelo).etiqueta}» (${(r.confianza * 100).toStringAsFixed(0)}% de confianza).', key: const Key('razon'), style: const TextStyle(fontSize: 12, height: 1.35)),
          if (r.plan != null)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const Key('plan-embalaje'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: const Text('Ver plan de embalaje', style: TextStyle(fontSize: 12.5, color: doom, fontWeight: FontWeight.w600)),
                children: [
                  for (final m in r.plan!.materiales) Align(alignment: Alignment.centerLeft, child: Text('• $m', style: const TextStyle(fontSize: 12, height: 1.4))),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text('Seguro: ${r.plan!.cobertura}', style: const TextStyle(fontSize: 12, color: gris))),
                  Align(alignment: Alignment.centerLeft, child: Text('Preparación: ${r.plan!.horas} h', style: const TextStyle(fontSize: 12, color: gris))),
                ],
              ),
            ),
          if (r.corregido)
            Container(
              key: const Key('correccion'),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ambar.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Las reglas de seguridad lo ajustaron', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                for (final x in r.reglas) Padding(padding: const EdgeInsets.only(top: 3), child: Text('• ${x.motivo}', style: const TextStyle(fontSize: 12, height: 1.3))),
              ]),
            ),
        ]),
        ),
      ),
    );
  }
}
