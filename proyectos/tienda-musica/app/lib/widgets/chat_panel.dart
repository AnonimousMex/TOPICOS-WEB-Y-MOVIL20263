import 'package:flutter/material.dart';

import '../api.dart';
import '../pages/producto_page.dart';
import '../pages/recomendar_page.dart';
import '../state.dart';
import '../theme.dart';
import 'producto_visual.dart';

/// Conversación con el asistente. Se usa como panel flotante (web) o a pantalla completa (móvil).
class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, this.onCerrar});
  final VoidCallback? onCerrar;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  int _vistos = 0;

  void _enviar(Tienda t, [String? sugerido]) {
    final texto = sugerido ?? _texto.text;
    _texto.clear();
    t.enviarChat(texto);
  }

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.of(context);
    if (t.chat.length != _vistos || t.chatEnviando) {
      _vistos = t.chat.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    }
    final ultima = t.chat.isNotEmpty ? t.chat.last.respuesta : null;
    final sugerencias = ultima?.sugerencias ?? (t.chat.length <= 1 ? t.sugerenciasIniciales : const <String>[]);
    return Material(
      color: fondo,
      child: Column(children: [
        Container(
          color: acero,
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(children: [
            const CircleAvatar(radius: 18, backgroundColor: doomBrillo, child: Icon(Icons.support_agent, color: acero)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Asistente Tesitura', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                Text('Productos, pedidos, envíos y garantía', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ]),
            ),
            if (widget.onCerrar != null) IconButton(tooltip: 'Cerrar', color: Colors.white, icon: const Icon(Icons.close), onPressed: widget.onCerrar),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: t.chat.length + (t.chatEnviando ? 1 : 0),
            itemBuilder: (_, i) => i == t.chat.length ? const _Escribiendo() : _Burbuja(mensaje: t.chat[i]),
          ),
        ),
        if (sugerencias.isNotEmpty && !t.chatEnviando)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final s in sugerencias)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: ActionChip(label: Text(s, style: const TextStyle(fontSize: 12, color: tinta)), backgroundColor: superficieAlta, side: BorderSide(color: doomBrillo.withValues(alpha: 0.45)), onPressed: () => _enviar(t, s)),
                  ),
              ],
            ),
          ),
        Container(
          color: superficie,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(children: [
            Expanded(
              child: TextField(
                key: const Key('mensaje'),
                controller: _texto,
                onSubmitted: (_) => _enviar(t),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: bordeSutil)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: bordeSutil)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(key: const Key('enviar'), style: IconButton.styleFrom(backgroundColor: doom), icon: const Icon(Icons.send_rounded, size: 20), onPressed: () => _enviar(t)),
          ]),
        ),
      ]),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});
  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final propio = mensaje.propio;
    final r = mensaje.respuesta;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: propio ? doom : superficieAlta,
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(propio ? 16 : 4), bottomRight: Radius.circular(propio ? 4 : 16)),
            ),
            child: Text(mensaje.texto, style: TextStyle(color: propio ? Colors.white : tinta, height: 1.35, fontSize: 14)),
          ),
          if (r != null) ...[
            for (final p in r.productos) _TarjetaProducto(p: p),
            if (r.accion == 'abrir_recomendador')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.tonal(
                  key: const Key('abrir-recomendador'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40), backgroundColor: doomSuave, foregroundColor: doomClaro),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecomendarPage(api: TiendaScope.leer(context).api))),
                  child: const Text('Abrir recomendador de embalaje'),
                ),
              ),
            if (r.fuentes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 6, children: [for (final f in r.fuentes) Chip(visualDensity: VisualDensity.compact, avatar: const Icon(Icons.menu_book_outlined, size: 14, color: gris), label: Text('Fuente: $f', style: const TextStyle(fontSize: 11, color: tinta)), backgroundColor: superficieAlta)]),
              ),
            if (r.aviso != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(r.aviso!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: grisClaro))),
            _Calificar(mensaje: mensaje),
            if (r.capas.isNotEmpty) _Traza(capas: r.capas),
          ],
        ]),
      ),
    );
  }
}

class _Calificar extends StatelessWidget {
  const _Calificar({required this.mensaje});
  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.leer(context);
    if (mensaje.respuesta?.consultaId == null) return const SizedBox.shrink();
    Widget boton(int valor, IconData icono, String tip, Key k) => IconButton(
          key: k,
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: mensaje.feedback == valor ? doom : grisClaro,
          icon: Icon(mensaje.feedback == valor ? (valor == 1 ? Icons.thumb_up : Icons.thumb_down) : icono),
          onPressed: mensaje.feedback == null ? () => t.calificar(mensaje, valor) : null,
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('¿Te sirvió?', style: TextStyle(fontSize: 11, color: grisClaro)),
      boton(1, Icons.thumb_up_outlined, 'Sí', const Key('util')),
      boton(-1, Icons.thumb_down_outlined, 'No', const Key('no-util')),
    ]);
  }
}

class _Traza extends StatelessWidget {
  const _Traza({required this.capas});
  final List<MapEntry<String, String>> capas;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        visualDensity: VisualDensity.compact,
        title: const Text('¿Cómo respondí?', style: TextStyle(fontSize: 12, color: doom, fontWeight: FontWeight.w600)),
        children: [
          for (final c in capas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(top: 2, right: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: doomSuave, borderRadius: BorderRadius.circular(4)), child: Text(c.key, style: const TextStyle(fontSize: 10, color: doom, fontWeight: FontWeight.w700))),
                Expanded(child: Text(c.value, style: const TextStyle(fontSize: 11, color: gris, height: 1.3))),
              ]),
            ),
        ],
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({required this.p});
  final TarjetaChat p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final api = TiendaScope.leer(context).api;
            final nav = Navigator.of(context);
            try {
              final producto = await api.producto(p.id);
              nav.push(MaterialPageRoute(builder: (_) => ProductoPage(producto: producto)));
            } on ApiException {/* sin red: no se abre */}
          },
          child: Row(children: [
            SizedBox(width: 84, child: ProductoVisual(categoria: p.categoria, marca: p.marca, imagenUrl: p.imagenUrl, alto: 84, compacto: true)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.2)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(dinero(p.precio), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (p.precioOriginal != null) ...[const SizedBox(width: 6), Text(dinero(p.precioOriginal!), style: const TextStyle(fontSize: 11, color: grisClaro, decoration: TextDecoration.lineThrough))],
                  ]),
                  Row(children: [Estrellas(p.rating, tam: 12), const SizedBox(width: 4), Text('${p.rating}', style: const TextStyle(fontSize: 11, color: grisClaro))]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(width: 36, child: LinearProgressIndicator(minHeight: 3, color: doom, backgroundColor: Color(0x14000000))),
      ),
    );
  }
}

/// Pantalla completa del chat (móvil).
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: ChatPanel(onCerrar: () => Navigator.pop(context))));
}
