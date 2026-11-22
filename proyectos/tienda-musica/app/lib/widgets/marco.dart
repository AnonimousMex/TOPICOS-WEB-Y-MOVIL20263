import 'package:flutter/material.dart';

import '../pages/carrito_page.dart';
import '../pages/home_page.dart';
import '../pages/cuenta_page.dart';
import '../pages/listado_page.dart';
import '../pages/recomendar_page.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import 'chat_panel.dart';
import 'logo.dart';

bool esAncho(BuildContext c) => MediaQuery.sizeOf(c).width >= 900;

/// Estructura común de todas las pantallas: franja de anuncio, encabezado con buscador y carrito,
/// categorías, contenido y el asistente flotante.
class Marco extends StatelessWidget {
  const Marco({super.key, required this.child, this.busqueda = ''});
  final Widget child;
  final String busqueda;

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.of(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final alto = MediaQuery.sizeOf(context).height;
    final panelFlotante = t.chatAbierto && ancho >= 700;
    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            const _Anuncio(),
            _Cabecera(busqueda: busqueda),
            const _Categorias(),
            Expanded(child: child),
          ]),
          if (ancho >= 700)
            Positioned(
              right: 16,
              bottom: 16,
              width: 400,
              height: (alto - 140).clamp(380.0, 620.0),
              child: AnimatedSwitcher(
                duration: Anim.normal,
                switchInCurve: Anim.curva,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (hijo, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim), child: hijo)),
                child: panelFlotante
                    ? Material(key: const ValueKey('panel-chat'), elevation: 8, borderRadius: BorderRadius.circular(14), clipBehavior: Clip.antiAlias, child: ChatPanel(onCerrar: () => t.alternarChat(false)))
                    : const SizedBox.shrink(key: ValueKey('sin-panel')),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: AnimatedSwitcher(
              duration: Anim.normal,
              switchInCurve: Anim.curva,
              transitionBuilder: (hijo, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: hijo)),
              child: panelFlotante
                  ? const SizedBox.shrink(key: ValueKey('sin-boton'))
                  : FloatingActionButton.extended(
                      key: const Key('abrir-chat'),
                      backgroundColor: doom,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Asistente'),
                      onPressed: () {
                        if (ancho >= 700) {
                          t.alternarChat(true);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                        }
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Anuncio extends StatelessWidget {
  const _Anuncio();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: doomOscuro,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: const Text('Envío protegido en todos tus instrumentos · 12 meses sin intereses · Precios y modelos de demostración', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12)),
      );
}

class _Cabecera extends StatefulWidget {
  const _Cabecera({required this.busqueda});
  final String busqueda;

  @override
  State<_Cabecera> createState() => _CabeceraState();
}

class _CabeceraState extends State<_Cabecera> {
  late final _q = TextEditingController(text: widget.busqueda);

  void _buscar() {
    final q = _q.text.trim();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ListadoPage(filtro: Filtro(q: q))));
  }

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.of(context);
    final ancho = esAncho(context);
    final logo = InkWell(
      onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false),
      child: const MarcaTesitura(tam: 40),
    );
    final buscador = SizedBox(
      height: 42,
      child: TextField(
        key: const Key('busqueda'),
        controller: _q,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _buscar(),
        decoration: InputDecoration(
          hintText: 'Buscar instrumentos, marcas y más…',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          suffixIcon: IconButton(icon: const Icon(Icons.search, color: gris), onPressed: _buscar),
        ),
      ),
    );
    final carrito = IconButton(
      key: const Key('carrito'),
      tooltip: 'Carrito',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarritoPage())),
      icon: Badge(isLabelVisible: t.articulos > 0, label: AnimatedSwitcher(duration: Anim.rapida, transitionBuilder: (h, a) => ScaleTransition(scale: a, child: h), child: Text('${t.articulos}', key: ValueKey(t.articulos))), backgroundColor: doom, child: const Icon(Icons.shopping_cart_outlined, color: Colors.white)),
    );
    final cuenta = t.usuario == null
        ? TextButton.icon(
            key: const Key('ingresar'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            icon: const Icon(Icons.person_outline, color: Colors.white70, size: 20),
            label: const Text('Ingresar', style: TextStyle(color: Colors.white70)),
          )
        : PopupMenuButton<String>(
            key: const Key('menu-cuenta'),
            tooltip: t.usuario!.correo,
            color: superficieAlta,
            onSelected: (v) {
              if (v == 'compras') Navigator.push(context, MaterialPageRoute(builder: (_) => const MisComprasPage()));
              if (v == 'bitacora') Navigator.push(context, MaterialPageRoute(builder: (_) => const BitacoraPage()));
              if (v == 'salir') t.cerrarSesion();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text('${t.usuario!.nombre} · ${t.usuario!.esAdmin ? 'Administrador' : 'Cliente'}', style: const TextStyle(color: gris, fontSize: 12.5))),
              const PopupMenuItem(value: 'compras', child: Text('Mis compras')),
              if (t.usuario!.esAdmin) const PopupMenuItem(value: 'bitacora', child: Text('Bitácora de auditoría')),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión', key: Key('cerrar-sesion'))),
            ],
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: CircleAvatar(radius: 15, backgroundColor: doom, child: Text(t.usuario!.nombre.isEmpty ? '?' : t.usuario!.nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          );
    final servidor = IconButton(
      key: const Key('servidor'),
      tooltip: 'URL del servidor',
      icon: const Icon(Icons.settings_ethernet, color: Colors.white70),
      onPressed: () async {
        var url = t.api.baseUrl;
        final formulario = GlobalKey<FormState>();
        final nueva = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Servidor de la tienda'),
            content: Form(
              key: formulario,
              child: TextFormField(
                initialValue: url,
                key: const Key('campo-url'),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: (v) => url = v,
                validator: (v) {
                  try {
                    normalizarUrlServidor(v ?? '');
                    return null;
                  } on FormatException catch (e) {
                    return e.message;
                  }
                },
                decoration: const InputDecoration(labelText: 'Dirección del servidor', helperText: 'Usa el mismo servidor en web y celular.', hintText: 'http://192.168.1.10:18000/api'),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
                onPressed: () { if (formulario.currentState!.validate()) Navigator.pop(ctx, url); },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
        if (nueva != null && nueva.isNotEmpty && context.mounted) {
          try {
            await t.cambiarServidor(nueva);
          } catch (_) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el servidor. Inténtalo de nuevo.')));
            return;
          }
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false);
        }
      },
    );
    final enlaces = [
      _Enlace('Ofertas', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListadoPage(filtro: Filtro(oferta: true))))),
    ];
    return Container(
      decoration: const BoxDecoration(color: acero, border: Border(bottom: BorderSide(color: doomBrillo, width: 2))),
      padding: EdgeInsets.fromLTRB(ancho ? 24 : 12, 10, ancho ? 16 : 4, 10),
      child: ancho
          ? Row(children: [
              logo,
              const SizedBox(width: 28),
              Expanded(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: buscador)),
              const SizedBox(width: 20),
              for (final e in enlaces) Padding(padding: const EdgeInsets.only(right: 18), child: InkWell(onTap: e.onTap, child: Text(e.texto, style: const TextStyle(fontSize: 14, color: Colors.white70)))),
              const Spacer(),
              servidor,
              cuenta,
              carrito,
            ])
          : Column(children: [
              Row(children: [Expanded(child: logo), servidor, cuenta, carrito]),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(right: 8), child: buscador),
            ]),
    );
  }
}

class _Enlace {
  _Enlace(this.texto, this.onTap);
  final String texto;
  final VoidCallback onTap;
}

class _Categorias extends StatelessWidget {
  const _Categorias();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: superficie,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Item(icono: Icons.local_offer_outlined, texto: 'Ofertas', color: verde, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListadoPage(filtro: Filtro(oferta: true))))),
          for (final e in categorias.entries)
            _Item(icono: e.value.icono, texto: e.value.etiqueta, color: e.value.color, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListadoPage(filtro: Filtro(categoria: e.key))))),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icono, required this.texto, required this.color, required this.onTap});
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [Icon(icono, size: 17, color: color), const SizedBox(width: 6), Text(texto, style: const TextStyle(fontSize: 13, color: gris, fontWeight: FontWeight.w500))]),
        ),
      );
}

class PieDePagina extends StatelessWidget {
  const PieDePagina({super.key});

  @override
  Widget build(BuildContext context) {
    final beneficios = const [
      (Icons.local_shipping_outlined, 'Envío protegido', 'Embalaje y seguro según tu instrumento'),
      (Icons.replay_outlined, 'Devoluciones', 'Política simulada de la práctica'),
      (Icons.verified_outlined, 'Garantía', 'Cobertura según el fabricante'),
      (Icons.credit_card_outlined, '12 meses sin intereses', 'En compras participantes'),
    ];
    return Column(children: [
      Container(
        width: double.infinity,
        color: superficie,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Wrap(spacing: 40, runSpacing: 18, alignment: WrapAlignment.center, children: [
              for (final b in beneficios)
                SizedBox(
                  width: 240,
                  child: Row(children: [
                    Icon(b.$1, color: doom, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.$2, style: const TextStyle(fontWeight: FontWeight.w700)), Text(b.$3, style: const TextStyle(fontSize: 12, color: gris))])),
                  ]),
                ),
            ]),
          ),
        ),
      ),
      Container(
        width: double.infinity,
        color: acero,
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextButton.icon(
            key: const Key('herramienta-recomendador'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecomendarPage(api: TiendaScope.leer(context).api))),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: const Text('Herramienta de bodega: recomendador de embalaje', style: TextStyle(fontSize: 12.5)),
          ),
          const SizedBox(height: 6),
          const Text('Tesitura · Práctica académica (Tópicos Selectos de Tecnologías Web y Móvil). Catálogo, precios, calificaciones y existencias son datos de demostración; las marcas pertenecen a sus dueños.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ]),
      ),
    ]);
  }
}
