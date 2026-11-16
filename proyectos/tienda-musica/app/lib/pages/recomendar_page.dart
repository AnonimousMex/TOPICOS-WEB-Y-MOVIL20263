import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/marco.dart';
import 'compra_page.dart';

class RecomendarPage extends StatefulWidget {
  const RecomendarPage({super.key, required this.api, this.producto});
  final RumboApi api;
  final Producto? producto;

  @override
  State<RecomendarPage> createState() => _RecomendarPageState();
}

class _RecomendarPageState extends State<RecomendarPage> {
  final _formKey = GlobalKey<FormState>();
  late String _tipo = widget.producto?.categoria ?? 'guitarra';
  late final _valor = TextEditingController(text: widget.producto?.precio.toStringAsFixed(0) ?? '');
  late final _peso = TextEditingController(text: widget.producto?.peso.toString() ?? '');
  late final _dim = TextEditingController(text: widget.producto?.dimensionMax.toString() ?? '');
  final _distancia = TextEditingController();
  late bool _fragil = widget.producto?.fragil ?? true;
  final _cantidad = TextEditingController(text: '1');
  String _humedad = 'media', _zona = 'baja';
  bool _urgente = false, _usado = false;

  Recomendacion? _resultado;
  bool _cargando = false;
  String? _error;
  Map<String, String> _camposServidor = {};

  Envio _envio() => Envio(
        tipo: _tipo,
        valor: double.parse(_valor.text),
        peso: double.parse(_peso.text),
        dimensionMax: int.parse(_dim.text),
        distancia: int.parse(_distancia.text),
        fragil: _fragil,
        productoId: widget.producto?.id,
        cantidad: int.tryParse(_cantidad.text) ?? 1,
        humedad: _humedad,
        zona: _zona,
        urgente: _urgente,
        usado: _usado,
      );

  String? _validarNumero(String campo, String? v, {bool entero = false, double min = 0}) {
    if (_camposServidor[campo] != null) return _camposServidor[campo];
    final n = entero ? int.tryParse(v ?? '') : double.tryParse(v ?? '');
    if (n == null) return 'Escribe un ${entero ? 'entero' : 'número'}';
    if (n <= min) return 'Debe ser mayor que $min';
    return null;
  }

  Future<void> _calcular() async {
    setState(() {
      _camposServidor = {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final r = await widget.api.recomendar(_envio());
      if (mounted) setState(() => _resultado = r);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _camposServidor = e.campos;
        _resultado = null;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmar() async {
    setState(() => _cargando = true);
    try {
      final pedido = await widget.api.registrar(_envio());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CompraPage(pedidos: [pedido])));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Marco(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListaSuave(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            const _Explicacion(),
            if (widget.producto != null) _CabeceraProducto(producto: widget.producto!),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Datos del envío', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Text('Tipo de instrumento', style: TextStyle(fontSize: 12, color: gris)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in categorias.entries)
                        ChoiceChip(
                          key: Key('tipo-${e.key}'),
                          avatar: Icon(e.value.icono, size: 16, color: _tipo == e.key ? Colors.white : e.value.color),
                          label: Text(e.value.etiqueta),
                          selected: _tipo == e.key,
                          showCheckmark: false,
                          labelStyle: TextStyle(fontWeight: FontWeight.w600, color: _tipo == e.key ? Colors.white : null),
                          onSelected: (_) => setState(() => _tipo = e.key),
                        ),
                    ]),
                    const SizedBox(height: 18),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _campo('valor', _valor, 'Valor (MXN)', Icons.payments_outlined, (v) => _validarNumero('valor_mxn', v))),
                      const SizedBox(width: 12),
                      Expanded(child: _campo('peso', _peso, 'Peso (kg)', Icons.scale_outlined, (v) => _validarNumero('peso_kg', v))),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _campo('dimension', _dim, 'Dimensión mayor (cm)', Icons.straighten, (v) => _validarNumero('dimension_max_cm', v, entero: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _campo('distancia', _distancia, 'Distancia (km)', Icons.route_outlined, (v) => _validarNumero('distancia_km', v, entero: true))),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('humedad'),
                          initialValue: _humedad,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Humedad del destino'),
                          items: const [DropdownMenuItem(value: 'baja', child: Text('Baja')), DropdownMenuItem(value: 'media', child: Text('Media')), DropdownMenuItem(value: 'alta', child: Text('Alta'))],
                          onChanged: (v) => setState(() => _humedad = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('zona'),
                          initialValue: _zona,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Zona de riesgo'),
                          items: const [DropdownMenuItem(value: 'baja', child: Text('Baja')), DropdownMenuItem(value: 'media', child: Text('Media')), DropdownMenuItem(value: 'alta', child: Text('Alta'))],
                          onChanged: (v) => setState(() => _zona = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _campo('cantidad', _cantidad, 'Cantidad de piezas', Icons.numbers, (v) => _validarNumero('cantidad', v, entero: true))),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ]),
                    SwitchListTile(key: const Key('urgente'), contentPadding: EdgeInsets.zero, title: const Text('Envío urgente'), value: _urgente, onChanged: (v) => setState(() => _urgente = v)),
                    SwitchListTile(key: const Key('usado'), contentPadding: EdgeInsets.zero, title: const Text('Instrumento usado'), value: _usado, onChanged: (v) => setState(() => _usado = v)),
                    Material(
                      color: crema,
                      borderRadius: BorderRadius.circular(14),
                      child: SwitchListTile(
                        key: const Key('fragil'),
                        title: const Text('Frágil', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Requiere manejo con cuidado'),
                        value: _fragil,
                        onChanged: (v) => setState(() => _fragil = v),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('calcular'),
              icon: _cargando ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
              label: const Text('Calcular recomendación'),
              onPressed: _cargando ? null : _calcular,
            ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!)),
                ]),
              ),
            if (_resultado != null) _Resultado(r: _resultado!, onConfirmar: _cargando ? null : _confirmar),
          ]),
        ),
      ),
    );
  }

  Widget _campo(String clave, TextEditingController c, String etiqueta, IconData icono, String? Function(String?) validar) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          key: Key(clave),
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono, size: 20)),
          validator: validar,
        ),
      );
}

class _CabeceraProducto extends StatelessWidget {
  const _CabeceraProducto({required this.producto});
  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final cat = categoriaDe(producto.categoria);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [cat.color, cat.color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(cat.icono, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(producto.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(dinero(producto.precio), style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
          ]),
        ),
      ]),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.r, required this.onConfirmar});
  final Recomendacion r;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    final fin = nivelDe(r.nivelFinal);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: fin.color,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(fin.icono, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Recomendación: ${r.nivelFinal.toUpperCase()}', key: const Key('nivel-final'), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(r.descripcion ?? fin.resumen, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.3)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Escala(modelo: r.nivelModelo, finalNivel: r.nivelFinal),
              const SizedBox(height: 14),
              Text('El modelo sugirió «${nivelDe(r.nivelModelo).etiqueta}» con ${(r.confianza * 100).toStringAsFixed(0)}% de confianza.'),
              const SizedBox(height: 12),
              if (r.corregido)
                Container(
                  key: const Key('correccion'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ambar.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: ambar.withValues(alpha: 0.6))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.rule_rounded, color: ambar),
                      SizedBox(width: 8),
                      Expanded(child: Text('Las reglas corrigieron al modelo', style: TextStyle(fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 8),
                    for (final x in r.reglas)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• ${x.efecto}: ${x.motivo}', style: const TextStyle(height: 1.3)),
                      ),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF3E8E5A).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF3E8E5A)),
                    SizedBox(width: 8),
                    Expanded(child: Text('Las reglas confirmaron la sugerencia.')),
                  ]),
                ),
              const SizedBox(height: 18),
              const Text('Alternativas', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final e in r.ranking)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(width: 82, child: Text(nivelDe(e.key).etiqueta, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: e.value, minHeight: 10, color: nivelDe(e.key).color, backgroundColor: bordeSutil),
                      ),
                    ),
                    SizedBox(width: 48, child: Text('${(e.value * 100).toStringAsFixed(0)}%', textAlign: TextAlign.end)),
                  ]),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('confirmar'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Confirmar y obtener folio'),
                onPressed: onConfirmar,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Escala visual de tres pasos: marca dónde cayó el modelo y dónde quedó tras las reglas.
class _Escala extends StatelessWidget {
  const _Escala({required this.modelo, required this.finalNivel});
  final String modelo, finalNivel;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (final k in ['basico', 'reforzado', 'premium']) ...[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: k == finalNivel ? nivelDe(k).color : nivelDe(k).color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: k == modelo && modelo != finalNivel ? Border.all(color: nivelDe(k).color, width: 2) : null,
            ),
            child: Column(children: [
              Icon(nivelDe(k).icono, size: 20, color: k == finalNivel ? Colors.white : nivelDe(k).color),
              const SizedBox(height: 2),
              Text(nivelDe(k).etiqueta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: k == finalNivel ? Colors.white : nivelDe(k).color)),
              if (k == modelo && modelo != finalNivel) Text('modelo', style: TextStyle(fontSize: 10, color: nivelDe(k).color)),
            ]),
          ),
        ),
        if (k != 'premium') const SizedBox(width: 6),
      ],
    ]);
  }
}


/// Explica para qué sirve esta pantalla: el comprador ya ve la recomendación en cada producto.
class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('explicacion-recomendador'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: doomSuave, borderRadius: BorderRadius.circular(10), border: Border.all(color: doomBrillo.withValues(alpha: 0.35))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.inventory_2_outlined, color: doomClaro),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recomendador de embalaje · herramienta de bodega', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 4),
            Text(
              'Aquí la tienda calcula cómo empacar y asegurar cualquier instrumento, incluso uno que no está en el catálogo, y registra la cotización con un folio. '
              'Si estás comprando no necesitas esta pantalla: cada producto ya muestra su recomendación al elegir tu ciudad.',
              style: TextStyle(fontSize: 13, color: gris, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}
