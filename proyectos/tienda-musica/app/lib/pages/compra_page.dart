import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/desplazamiento.dart';
import '../widgets/chat_panel.dart';
import '../widgets/marco.dart';
import 'home_page.dart';

/// Confirmación: un folio por cada producto, con el embalaje que decidió el recomendador.
class CompraPage extends StatelessWidget {
  const CompraPage({super.key, required this.pedidos, this.resultado, this.cliente});
  final List<PedidoRegistrado> pedidos;
  final ResultadoCompra? resultado;
  final String? cliente;

  void _preguntar(BuildContext context) {
    final t = TiendaScope.leer(context);
    final folio = pedidos.first.folio;
    if (MediaQuery.sizeOf(context).width >= 700) {
      t.alternarChat(true);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
    }
    t.enviarChat('¿Cómo va mi pedido $folio?');
  }

  @override
  Widget build(BuildContext context) {
    return Marco(
      child: ListaSuave(children: [
        Centrado(
          ancho: 760,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 8),
              Center(child: Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: verde, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 46, color: Colors.white))),
              const SizedBox(height: 14),
              Text(cliente != null && cliente!.isNotEmpty ? '¡Gracias por tu compra, $cliente!' : '¡Pedido registrado!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(pedidos.length == 1 ? 'Este es tu folio:' : 'Estos son tus ${pedidos.length} folios (uno por producto):', textAlign: TextAlign.center, style: const TextStyle(color: gris)),
              const SizedBox(height: 18),
              for (final p in pedidos) _Folio(p: p),
              if (resultado != null) _PagoYCorreo(c: resultado!.compra),
              if (resultado != null)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(6)),
                  child: Column(children: [
                    _Total('Productos', dinero(resultado!.subtotal)),
                    _Total('Embalaje y seguro', resultado!.embalaje == 0 ? 'Incluido' : dinero(resultado!.embalaje)),
                    const Divider(height: 20),
                    _Total('Total', dinero(resultado!.total), grande: true),
                  ]),
                ),
              const SizedBox(height: 18),
              OutlinedButton.icon(key: const Key('preguntar-asistente'), icon: const Icon(Icons.chat_bubble_outline, size: 18), label: const Text('Preguntar al asistente por mi pedido'), onPressed: () => _preguntar(context)),
              const SizedBox(height: 10),
              FilledButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false), child: const Text('Seguir comprando')),
            ]),
          ),
        ),
        const PieDePagina(),
      ]),
    );
  }
}

class _PagoYCorreo extends StatelessWidget {
  const _PagoYCorreo({required this.c});
  final CompraInfo c;

  @override
  Widget build(BuildContext context) {
    final (icono, color, texto) = switch (c.correoEstado) {
      'enviado' => (Icons.mark_email_read_outlined, verde, 'Te enviamos la confirmación a ${c.correo}.'),
      'simulado' => (Icons.mark_email_unread_outlined, ambar, 'Modo de pruebas: el correo para ${c.correo} no salió a internet; quedó guardado en la bandeja de pruebas del servidor (backend/correos_enviados).'),
      _ => (Icons.error_outline, Colors.red, 'No pudimos enviar el correo a ${c.correo}, pero tu compra quedó registrada con la referencia ${c.referencia}.'),
    };
    return Container(
      key: const Key('pago-correo'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_outlined, color: verde),
          const SizedBox(width: 10),
          Expanded(child: Text('Pago aprobado (simulado) · ${c.pagoMarca.toUpperCase()} •••• ${c.pagoUltimos4}', style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        Padding(padding: const EdgeInsets.only(left: 34, top: 2), child: Text('Referencia de pago ${c.pagoReferencia} · compra ${c.referencia}', style: const TextStyle(fontSize: 12, color: gris))),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, key: const Key('estado-correo'), style: const TextStyle(fontSize: 13, height: 1.35))),
        ]),
      ]),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.a, this.b, {this.grande = false});
  final String a, b;
  final bool grande;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(a, style: TextStyle(fontSize: grande ? 18 : 14, fontWeight: grande ? FontWeight.w600 : FontWeight.w400))), Text(b, style: TextStyle(fontSize: grande ? 22 : 14, fontWeight: grande ? FontWeight.w700 : FontWeight.w500))]));
}

class _Folio extends StatelessWidget {
  const _Folio({required this.p});
  final PedidoRegistrado p;

  @override
  Widget build(BuildContext context) {
    final n = nivelDe(p.recomendacion.nivelFinal);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: n.color, width: 5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.producto != null) Text('${p.cantidad > 1 ? '${p.cantidad} × ' : ''}${p.producto}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: SelectableText(p.folio, key: const Key('folio'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1, color: doom))),
          IconButton(tooltip: 'Copiar folio', icon: const Icon(Icons.copy_rounded, size: 18), onPressed: () {
            Clipboard.setData(ClipboardData(text: p.folio));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folio copiado'), duration: Duration(seconds: 1)));
          }),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Insignia('Embalaje ${n.etiqueta}', n.color),
          if (p.recomendacion.corregido) const Insignia('Ajustado por reglas de seguridad', ambar),
          if (p.destino.isNotEmpty) Insignia('Envío a ${p.destino}', gris),
        ]),
      ]),
    );
  }
}
