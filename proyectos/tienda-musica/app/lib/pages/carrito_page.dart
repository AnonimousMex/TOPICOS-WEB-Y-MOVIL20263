import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/marco.dart';
import '../widgets/producto_visual.dart';
import '../widgets/selector_destino.dart';
import '../widgets/tarjeta_form.dart';
import 'compra_page.dart';
import 'cuenta_page.dart';
import 'home_page.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  List<Destino> _destinos = [];
  final _nombre = TextEditingController();
  final _tarjeta = TarjetaControles();
  final Map<int, Recomendacion> _envios = {};
  bool _cotizando = false, _comprando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    final t = TiendaScope.leer(context);
    try {
      final d = await t.api.destinos();
      if (!mounted) return;
      setState(() => _destinos = d);
      await _cotizarTodo();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _cotizarTodo() async {
    final t = TiendaScope.leer(context);
    if (t.destino == null || t.lineas.isEmpty) return;
    setState(() {
      _cotizando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([for (final l in t.lineas) t.api.cotizarEnvio(l.producto.id, l.cantidad, t.destino!)]);
      if (!mounted) return;
      setState(() {
        _envios.clear();
        for (var i = 0; i < t.lineas.length; i++) {
          _envios[t.lineas[i].producto.id] = r[i];
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cotizando = false);
    }
  }

  Future<void> _comprar() async {
    final t = TiendaScope.leer(context);
    setState(() {
      _comprando = true;
      _error = null;
    });
    try {
      final r = await t.api.comprar(
        cliente: _nombre.text.trim(),
        correo: t.usuario!.correo,
        destino: t.destino!,
        tarjeta: _tarjeta.aTarjeta(),
        lineas: [for (final l in t.lineas) (productoId: l.producto.id, cantidad: l.cantidad)],
      );
      t.vaciar();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompraPage(pedidos: r.pedidos, resultado: r, cliente: _nombre.text.trim())));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _comprando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.of(context);
    final ancho = esAncho(context);
    if (t.lineas.isEmpty) {
      return Marco(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_outlined, size: 72, color: grisClaro),
            const SizedBox(height: 12),
            const Text('Tu carrito está vacío', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Agrega instrumentos y calcula tu envío protegido.', style: TextStyle(color: gris)),
            const SizedBox(height: 18),
            FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(220, 46)), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false), child: const Text('Descubrir productos')),
          ]),
        ),
      );
    }
    final listo = t.destino != null && t.conSesion && _nombre.text.trim().length >= 2 && _tarjeta.completa && _envios.length == t.lineas.length && !_cotizando && !_comprando;
    final embalaje = _envios.values.fold<int>(0, (s, r) => s + r.costo);
    final lineas = Container(
      decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(6)),
      child: Column(children: [
        for (final l in List.of(t.lineas)) ...[
          _Linea(linea: l, envio: _envios[l.producto.id], cotizando: _cotizando, onCantidad: (c) {
            t.cambiarCantidad(l, c);
            _cotizarTodo();
          }, onQuitar: () {
            t.quitar(l);
            _envios.remove(l.producto.id);
          }),
          if (l != t.lineas.last) const Divider(),
        ],
      ]),
    );
    final resumen = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Resumen de compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        TextField(key: const Key('nombre'), controller: _nombre, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Tu nombre', isDense: true)),
        const SizedBox(height: 10),
        if (t.usuario != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.mail_outline, size: 16, color: gris), const SizedBox(width: 6), Expanded(child: Text('Confirmación a ${t.usuario!.correo}', style: const TextStyle(color: gris, fontSize: 12.5)))]))
        else
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              key: const Key('login-para-pagar'),
              onPressed: () async {
                final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                if (ok == true && mounted && _nombre.text.trim().isEmpty) setState(() => _nombre.text = TiendaScope.leer(context).usuario?.nombre ?? '');
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('Inicia sesión para pagar'),
            ),
          ),
        const SizedBox(height: 12),
        SelectorDestino(destinos: _destinos, onCambio: () {
          setState(() {});
          _cotizarTodo();
        }),
        const SizedBox(height: 14),
        const Text('Pago', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FormularioTarjeta(controles: _tarjeta, onCambio: () => setState(() {})),
        const SizedBox(height: 16),
        _Fila('Productos (${t.articulos})', dinero(t.subtotal)),
        _Fila('Embalaje y seguro', t.destino == null ? 'Elige tu destino' : (_cotizando ? 'Calculando…' : (embalaje == 0 ? 'Incluido' : dinero(embalaje))), color: embalaje == 0 && _envios.isNotEmpty ? verde : null),
        const Divider(height: 24),
        _Fila('Total', dinero(t.subtotal + embalaje), grande: true),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, key: const Key('error-compra'), style: const TextStyle(color: Colors.red, fontSize: 13))),
        const SizedBox(height: 14),
        FilledButton(key: const Key('confirmar-compra'), onPressed: listo ? _comprar : null, child: _comprando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Pagar ${dinero(t.subtotal + embalaje)}')),
      ]),
    );
    return Marco(
      child: ListaSuave(children: [
        Centrado(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ancho
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: lineas), const SizedBox(width: 16), SizedBox(width: 400, child: resumen)])
                : Column(children: [lineas, const SizedBox(height: 12), resumen]),
          ),
        ),
        const PieDePagina(),
      ]),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.grande = false, this.color});
  final String etiqueta, valor;
  final bool grande;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(etiqueta, style: TextStyle(fontSize: grande ? 18 : 14, fontWeight: grande ? FontWeight.w600 : FontWeight.w400))), Text(valor, style: TextStyle(fontSize: grande ? 22 : 14, fontWeight: grande ? FontWeight.w700 : FontWeight.w500, color: color))]),
      );
}

class _Linea extends StatelessWidget {
  const _Linea({required this.linea, required this.envio, required this.cotizando, required this.onCantidad, required this.onQuitar});
  final LineaCarrito linea;
  final Recomendacion? envio;
  final bool cotizando;
  final ValueChanged<int> onCantidad;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final p = linea.producto;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 92, child: ProductoVisual(categoria: p.categoria, marca: p.marca, imagenUrl: p.imagenMini ?? p.imagenUrl, alto: 92, compacto: true))),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: const TextStyle(fontSize: 15, height: 1.25)),
            const SizedBox(height: 2),
            Text(p.marca, style: const TextStyle(fontSize: 12, color: gris)),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: bordeSutil), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove, size: 18), onPressed: linea.cantidad > 1 ? () => onCantidad(linea.cantidad - 1) : null),
                  Text('${linea.cantidad}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add, size: 18), onPressed: () => onCantidad(linea.cantidad + 1)),
                ]),
              ),
              TextButton(onPressed: onQuitar, child: const Text('Eliminar')),
            ]),
            if (envio != null && !cotizando)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(nivelDe(envio!.nivelFinal).icono, size: 16, color: nivelDe(envio!.nivelFinal).color),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Embalaje ${nivelDe(envio!.nivelFinal).etiqueta}${envio!.corregido ? ' (ajustado por reglas)' : ''} · ${envio!.costo == 0 ? 'incluido' : dinero(envio!.costo)}', style: TextStyle(fontSize: 12.5, color: nivelDe(envio!.nivelFinal).color, fontWeight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Text(dinero(linea.subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
