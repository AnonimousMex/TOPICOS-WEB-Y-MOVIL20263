import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/marco.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/precarga.dart';
import '../widgets/logo.dart';
import '../widgets/producto_card.dart';
import '../widgets/producto_visual.dart';
import 'listado_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Facetas? _facetas;
  List<Producto> _ofertas = [], _vendidos = [], _teclados = [], _guitarras = [];
  bool _cargando = true;
  String? _error;
  final _hero = PageController();
  int _slide = 0;

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
      final r = await Future.wait([
        api.facetas(),
        api.productos(const Filtro(oferta: true, orden: 'mas_vendidos')),
        api.productos(const Filtro(orden: 'mas_vendidos')),
        api.productos(const Filtro(categoria: 'teclado', orden: 'mejor_valorados')),
        api.productos(const Filtro(categoria: 'guitarra', orden: 'mejor_valorados')),
      ]);
      if (!mounted) return;
      setState(() {
        _facetas = r[0] as Facetas;
        _ofertas = (r[1] as List<Producto>).take(10).toList();
        _vendidos = (r[2] as List<Producto>).take(10).toList();
        _teclados = (r[3] as List<Producto>).take(10).toList();
        _guitarras = (r[4] as List<Producto>).take(10).toList();
      });
      precargarFotos(context, [..._ofertas, ..._vendidos, ..._guitarras, ..._teclados]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _ir(Filtro f) => Navigator.push(context, MaterialPageRoute(builder: (_) => ListadoPage(filtro: f)));

  @override
  Widget build(BuildContext context) {
    return Marco(
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? SingleChildScrollView(child: ErrorConReintento(mensaje: _error!, onReintentar: _cargar))
              : ListaSuave(children: [
                  Centrado(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(children: [
                        _Hero(controller: _hero, slide: _slide, onCambio: (i) => setState(() => _slide = i), onIr: _ir),
                        const SizedBox(height: 16),
                        _Marcas(marcas: _facetas!.marcas, onMarca: (m) => _ir(Filtro(marcas: {m}))),
                        const SizedBox(height: 16),
                        Seccion(titulo: 'Ofertas del día', accion: 'Ver todas', alAccion: () => _ir(const Filtro(oferta: true)), child: FilaProductos(productos: _ofertas)),
                        Seccion(titulo: 'Los más vendidos', accion: 'Ver más', alAccion: () => _ir(const Filtro(orden: 'mas_vendidos')), child: FilaProductos(productos: _vendidos)),
                        Seccion(titulo: 'Guitarras y bajos mejor valorados', accion: 'Ver todo', alAccion: () => _ir(const Filtro(categoria: 'guitarra', orden: 'mejor_valorados')), child: FilaProductos(productos: _guitarras)),
                        Seccion(titulo: 'Teclados y pianos', accion: 'Ver todo', alAccion: () => _ir(const Filtro(categoria: 'teclado', orden: 'mejor_valorados')), child: FilaProductos(productos: _teclados)),
                      ]),
                    ),
                  ),
                  const PieDePagina(),
                ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.controller, required this.slide, required this.onCambio, required this.onIr});
  final PageController controller;
  final int slide;
  final ValueChanged<int> onCambio;
  final ValueChanged<Filtro> onIr;

  @override
  Widget build(BuildContext context) {
    const slides = [
      ('Ofertas de temporada', 'Hasta 20% de descuento en guitarras, teclados y baterías.', 'Ver ofertas', Filtro(oferta: true)),
      ('Envío protegido para tu instrumento', 'Un modelo entrenado y reglas de seguridad eligen el embalaje y el seguro según valor, peso, humedad y distancia.', 'Explorar guitarras', Filtro(categoria: 'guitarra')),
      ('Más de 50 marcas', 'Yamaha, Fender, Roland, Pearl, Shure y muchas más en un solo lugar.', 'Ver más vendidos', Filtro(orden: 'mas_vendidos')),
    ];
    final ancho = esAncho(context);
    return Container(
      height: ancho ? 280 : 250,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: bordeSutil)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF05100C), Color(0xFF0E3326)], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
        if (ancho) const Positioned(right: 70, top: 0, bottom: 0, child: Center(child: LogoTesitura(tam: 230, opacidad: 0.16))),
        PageView.builder(
          controller: controller,
          onPageChanged: onCambio,
          itemCount: slides.length,
          itemBuilder: (_, i) {
            final s = slides[i];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: ancho ? 70 : 24, vertical: 22),
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: TextStyle(color: Colors.white, fontSize: ancho ? 34 : 22, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 10),
                    Text(s.$2, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: ancho ? 15 : 12.5, height: 1.4)),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: doomBrillo, foregroundColor: acero, minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 24)),
                      onPressed: () => onIr(s.$4),
                      child: Text(s.$3),
                    ),
                  ]),
                ),
                if (ancho) const Expanded(flex: 2, child: SizedBox()),
              ]),
            );
          },
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(duration: Anim.normal, curve: Anim.curva, margin: const EdgeInsets.all(3), width: i == slide ? 22 : 8, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: i == slide ? doomBrillo : Colors.white.withValues(alpha: 0.35))),
          ]),
        ),
        if (ancho) ...[
          Positioned(left: 8, top: 0, bottom: 0, child: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 34), onPressed: () => controller.previousPage(duration: Anim.normal, curve: Anim.curva))),
          Positioned(right: 8, top: 0, bottom: 0, child: IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 34), onPressed: () => controller.nextPage(duration: Anim.normal, curve: Anim.curva))),
        ],
      ]),
    );
  }
}

class _Marcas extends StatelessWidget {
  const _Marcas({required this.marcas, required this.onMarca});
  final List<Marca> marcas;
  final ValueChanged<String> onMarca;

  @override
  Widget build(BuildContext context) {
    return Seccion(
      titulo: 'Marcas populares',
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: marcas.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final m = marcas[i];
            return InkWell(
              key: Key('marca-${m.nombre}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onMarca(m.nombre),
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: bordeSutil), borderRadius: BorderRadius.circular(8), color: superficieAlta),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  MarcaLogo(nombre: m.nombre, logoUrl: m.logo, alto: 44, ancho: 130),
                  const SizedBox(height: 4),
                  Text('${m.total} productos', style: const TextStyle(fontSize: 10, color: grisClaro)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
