import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/marco.dart';
import '../widgets/producto_card.dart';
import '../widgets/producto_visual.dart';

const _ordenes = {
  'relevancia': 'Más relevantes',
  'mas_vendidos': 'Más vendidos',
  'precio_asc': 'Menor precio',
  'precio_desc': 'Mayor precio',
  'mejor_valorados': 'Mejor valorados',
};

class ListadoPage extends StatefulWidget {
  const ListadoPage({super.key, required this.filtro});
  final Filtro filtro;

  @override
  State<ListadoPage> createState() => _ListadoPageState();
}

class _ListadoPageState extends State<ListadoPage> {
  late Filtro _filtro = widget.filtro;
  List<Producto> _productos = [];
  Facetas? _facetas;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final api = TiendaScope.leer(context).api;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([api.productos(_filtro), if (_facetas == null) api.facetas()]);
      if (!mounted) return;
      setState(() {
        _productos = r[0] as List<Producto>;
        if (r.length > 1) _facetas = r[1] as Facetas;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicar(Filtro nuevo) {
    setState(() => _filtro = nuevo);
    _cargar();
  }

  String get _titulo {
    if (_filtro.q.isNotEmpty) return _filtro.q;
    if (_filtro.oferta) return 'Ofertas';
    if (_filtro.marcas.length == 1) return _filtro.marcas.first;
    if (_filtro.categoria != null) return categoriaDe(_filtro.categoria!).etiqueta;
    return 'Todos los instrumentos';
  }

  Future<void> _abrirFiltros() async {
    var tmp = _filtro;
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: superficie,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, scroll) => Column(children: [
            Expanded(child: SingleChildScrollView(controller: scroll, padding: const EdgeInsets.all(16), child: PanelFiltros(filtro: tmp, facetas: _facetas, onCambio: (f) => setM(() => tmp = f)))),
            Padding(padding: const EdgeInsets.all(12), child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ver resultados'))),
          ]),
        ),
      ),
    );
    if (aplicar == true) _aplicar(tmp);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = esAncho(context);
    final orden = Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Ordenar por ', style: TextStyle(color: gris, fontSize: 13)),
      DropdownButton<String>(
        key: const Key('orden'),
        value: _filtro.orden,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: tinta, fontSize: 13),
        dropdownColor: superficieAlta,
        items: [for (final e in _ordenes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: (v) => _aplicar(_filtro.copiar(orden: v)),
      ),
    ]);
    final cabecera = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(children: [
        if (_filtro.marcas.length == 1 && _facetas != null)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MarcaLogo(nombre: _filtro.marcas.first, logoUrl: _facetas!.marcas.where((m) => m.nombre == _filtro.marcas.first).firstOrNull?.logo, alto: 48, ancho: 120),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            Text(_cargando ? 'Buscando…' : '${_productos.length} resultados', key: const Key('total'), style: const TextStyle(color: gris, fontSize: 13)),
          ]),
        ),
        if (!ancho) TextButton.icon(onPressed: _abrirFiltros, icon: const Icon(Icons.tune), label: Text(_filtro.activos > 0 ? 'Filtros (${_filtro.activos})' : 'Filtros')),
        orden,
      ]),
    );
    final resultados = DesplazamientoSuave(
      builder: (ctx, c, fisica) => CustomScrollView(
        controller: c,
        physics: fisica,
        slivers: [
          SliverToBoxAdapter(child: cabecera),
          SliverToBoxAdapter(child: AnimatedSize(duration: Anim.normal, curve: Anim.curva, child: _cargando ? const LinearProgressIndicator(minHeight: 2, color: doomBrillo) : const SizedBox(width: double.infinity))),
          if (_error != null) SliverToBoxAdapter(child: ErrorConReintento(mensaje: _error!, onReintentar: _cargar))
          else if (_productos.isEmpty && _cargando) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator())))
          else if (_productos.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Column(children: [Icon(Icons.search_off, size: 52, color: grisClaro), SizedBox(height: 8), Text('No encontramos publicaciones con esos filtros.'), Text('Prueba quitando algún filtro o buscando otra marca.', style: TextStyle(color: gris))]))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverAnimatedOpacity(
                opacity: _cargando ? 0.45 : 1,
                duration: Anim.normal,
                curve: Anim.curva,
                // SliverGrid construye solo las tarjetas que se ven: con ~200 productos es lo que mantiene fluido el desplazamiento
                sliver: SliverGrid.builder(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 250, mainAxisExtent: alturaTarjeta, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _productos.length,
                  itemBuilder: (_, i) => ProductoCard(key: ValueKey(_productos[i].id), producto: _productos[i]),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 28), child: Center(child: Text('Catálogo, precios, calificaciones y existencias son datos de demostración.', style: TextStyle(color: grisClaro, fontSize: 12))))),
        ],
      ),
    );
    return Marco(
      busqueda: _filtro.q,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (ancho) SizedBox(width: 262, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), child: PanelFiltros(filtro: _filtro, facetas: _facetas, onCambio: _aplicar))),
            Expanded(child: resultados),
          ]),
        ),
      ),
    );
  }
}

class PanelFiltros extends StatefulWidget {
  const PanelFiltros({super.key, required this.filtro, required this.facetas, required this.onCambio});
  final Filtro filtro;
  final Facetas? facetas;
  final ValueChanged<Filtro> onCambio;

  @override
  State<PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<PanelFiltros> {
  bool _todasMarcas = false;
  late final _min = TextEditingController(text: widget.filtro.min?.round().toString() ?? '');
  late final _max = TextEditingController(text: widget.filtro.max?.round().toString() ?? '');

  Widget _titulo(String t) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)));

  @override
  Widget build(BuildContext context) {
    final f = widget.filtro;
    final fa = widget.facetas;
    final marcas = fa?.marcas ?? const <Marca>[];
    final visibles = _todasMarcas ? marcas : marcas.take(10).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
        if (f.activos > 0)
          TextButton(
            onPressed: () {
              _min.clear();
              _max.clear();
              widget.onCambio(Filtro(q: f.q, orden: f.orden));
            },
            child: const Text('Limpiar'),
          ),
      ]),
      _titulo('Categoría'),
      if (fa != null)
        for (final e in categorias.entries)
          if (fa.categorias.containsKey(e.key))
            InkWell(
              onTap: () => widget.onCambio(f.categoria == e.key ? f.copiar(limpiarCategoria: true) : f.copiar(categoria: e.key)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Icon(e.value.icono, size: 16, color: f.categoria == e.key ? doom : gris),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value.etiqueta, style: TextStyle(fontSize: 13, color: f.categoria == e.key ? doom : tinta, fontWeight: f.categoria == e.key ? FontWeight.w700 : FontWeight.w400))),
                  Text('(${fa.categorias[e.key]})', style: const TextStyle(fontSize: 12, color: grisClaro)),
                ]),
              ),
            ),
      _titulo('Marca'),
      for (final m in visibles)
        InkWell(
          key: Key('filtro-marca-${m.nombre}'),
          onTap: () {
            final s = {...f.marcas};
            s.contains(m.nombre) ? s.remove(m.nombre) : s.add(m.nombre);
            widget.onCambio(f.copiar(marcas: s));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(height: 24, width: 24, child: Checkbox(value: f.marcas.contains(m.nombre), onChanged: null, visualDensity: VisualDensity.compact)),
              const SizedBox(width: 6),
              Expanded(child: Text(m.nombre, style: const TextStyle(fontSize: 13))),
              Text('(${m.total})', style: const TextStyle(fontSize: 12, color: grisClaro)),
            ]),
          ),
        ),
      if (marcas.length > 10) TextButton(onPressed: () => setState(() => _todasMarcas = !_todasMarcas), child: Text(_todasMarcas ? 'Ver menos' : 'Ver las ${marcas.length} marcas')),
      _titulo('Precio'),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final r in const [('Hasta \$3,000', null, 3000.0), ('\$3,000 a \$10,000', 3000.0, 10000.0), ('Más de \$10,000', 10000.0, null)])
          ChoiceChip(
            label: Text(r.$1, style: const TextStyle(fontSize: 12)),
            selected: f.min == r.$2 && f.max == r.$3 && (f.min != null || f.max != null),
            onSelected: (_) {
              _min.text = r.$2?.round().toString() ?? '';
              _max.text = r.$3?.round().toString() ?? '';
              widget.onCambio(Filtro(q: f.q, categoria: f.categoria, marcas: f.marcas, min: r.$2, max: r.$3, oferta: f.oferta, envioGratis: f.envioGratis, disponible: f.disponible, orden: f.orden));
            },
          ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(key: const Key('precio-min'), controller: _min, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Mínimo', isDense: true))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-')),
        Expanded(child: TextField(key: const Key('precio-max'), controller: _max, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Máximo', isDense: true))),
        IconButton(
          key: const Key('aplicar-precio'),
          icon: const Icon(Icons.chevron_right, color: doom),
          onPressed: () => widget.onCambio(Filtro(q: f.q, categoria: f.categoria, marcas: f.marcas, min: double.tryParse(_min.text), max: double.tryParse(_max.text), oferta: f.oferta, envioGratis: f.envioGratis, disponible: f.disponible, orden: f.orden)),
        ),
      ]),
      _titulo('Más filtros'),
      _Interruptor('Solo ofertas', f.oferta, (v) => widget.onCambio(f.copiar(oferta: v))),
      _Interruptor('Envío gratis', f.envioGratis, (v) => widget.onCambio(f.copiar(envioGratis: v))),
      _Interruptor('Solo disponibles', f.disponible, (v) => widget.onCambio(f.copiar(disponible: v))),
    ]);
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor(this.texto, this.valor, this.onChanged);
  final String texto;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))), Switch(value: valor, onChanged: onChanged, activeTrackColor: doom)]);
}
