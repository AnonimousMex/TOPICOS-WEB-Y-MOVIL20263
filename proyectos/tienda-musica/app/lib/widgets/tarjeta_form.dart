import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../theme.dart';

String marcaDe(String numero) {
  final n = numero.replaceAll(' ', '');
  if (RegExp(r'^3[47]').hasMatch(n)) return 'AMEX';
  if (RegExp(r'^(5[1-5]|2(2[2-9]|[3-6]\d|7[01]|720))').hasMatch(n)) return 'MASTERCARD';
  if (n.startsWith('4')) return 'VISA';
  return '';
}

class TarjetaControles {
  final numero = TextEditingController();
  final titular = TextEditingController();
  final vence = TextEditingController();
  final cvv = TextEditingController();

  bool get completa {
    final n = numero.text.replaceAll(' ', '');
    return n.length >= 13 && titular.text.trim().length >= 3 && RegExp(r'^\d{2}/\d{2}$').hasMatch(vence.text) && cvv.text.length >= 3;
  }

  Tarjeta aTarjeta() => Tarjeta(numero: numero.text, titular: titular.text.trim(), vencimiento: vence.text, cvv: cvv.text);

  void rellenarDePrueba() {
    numero.text = '4242 4242 4242 4242';
    titular.text = titular.text.isEmpty ? 'TITULAR DE PRUEBA' : titular.text;
    vence.text = '12/30';
    cvv.text = '123';
  }
}

class _FormatoNumero extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final corto = d.length > 19 ? d.substring(0, 19) : d;
    final b = StringBuffer();
    for (var i = 0; i < corto.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(corto[i]);
    }
    return TextEditingValue(text: b.toString(), selection: TextSelection.collapsed(offset: b.length));
  }
}

class _FormatoVencimiento extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    var d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// Formulario de pago SIMULADO: solo acepta tarjetas de prueba. Nada de esto se guarda; el servidor solo conserva marca y 4 últimos dígitos.
class FormularioTarjeta extends StatefulWidget {
  const FormularioTarjeta({super.key, required this.controles, required this.onCambio});
  final TarjetaControles controles;
  final VoidCallback onCambio;

  @override
  State<FormularioTarjeta> createState() => _FormularioTarjetaState();
}

class _FormularioTarjetaState extends State<FormularioTarjeta> {
  TarjetaControles get c => widget.controles;

  @override
  void initState() {
    super.initState();
    for (final x in [c.numero, c.titular, c.vence, c.cvv]) {
      x.addListener(_cambio);
    }
  }

  @override
  void dispose() {
    for (final x in [c.numero, c.titular, c.vence, c.cvv]) {
      x.removeListener(_cambio);
    }
    super.dispose();
  }

  void _cambio() {
    if (mounted) setState(() {});
    widget.onCambio();
  }

  @override
  Widget build(BuildContext context) {
    final marca = marcaDe(c.numero.text);
    final n = c.numero.text.isEmpty ? '•••• •••• •••• ••••' : c.numero.text.padRight(19, '•');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        key: const Key('tarjeta-visual'),
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [Color(0xFF1F2A30), Color(0xFF0F3B2B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.contactless_outlined, color: doomBrillo),
            const Spacer(),
            Text(marca.isEmpty ? 'TARJETA' : marca, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
          ]),
          Text(n, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontFeatures: [FontFeature.tabularFigures()])),
          Row(children: [
            Expanded(child: Text(c.titular.text.isEmpty ? 'NOMBRE DEL TITULAR' : c.titular.text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            Text(c.vence.text.isEmpty ? 'MM/AA' : c.vence.text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      TextField(key: const Key('tarjeta-numero'), controller: c.numero, keyboardType: TextInputType.number, inputFormatters: [_FormatoNumero()], decoration: const InputDecoration(labelText: 'Número de tarjeta', isDense: true, prefixIcon: Icon(Icons.credit_card, size: 20))),
      const SizedBox(height: 10),
      TextField(key: const Key('tarjeta-titular'), controller: c.titular, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Nombre del titular', isDense: true)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(key: const Key('tarjeta-vence'), controller: c.vence, keyboardType: TextInputType.number, inputFormatters: [_FormatoVencimiento()], decoration: const InputDecoration(labelText: 'Vence (MM/AA)', isDense: true))),
        const SizedBox(width: 10),
        Expanded(child: TextField(key: const Key('tarjeta-cvv'), controller: c.cvv, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'CVV', isDense: true, counterText: ''))),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: ambar.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.science_outlined, size: 18, color: ambar),
          const SizedBox(width: 8),
          const Expanded(child: Text('Pago simulado: no se cobra nada. Solo se aceptan tarjetas de prueba; no escribas una tarjeta real.', style: TextStyle(fontSize: 11.5, height: 1.3))),
          TextButton(key: const Key('rellenar-prueba'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 30)), onPressed: () {
            c.rellenarDePrueba();
          }, child: const Text('Usar 4242…', style: TextStyle(fontSize: 12))),
        ]),
      ),
    ]);
  }
}
