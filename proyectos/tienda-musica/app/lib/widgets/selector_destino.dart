import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';

/// Elige la ciudad de entrega o usa tu ubicación actual. La ubicación se convierte en ciudad cercana y distancia;
/// las coordenadas viven solo en memoria y el servidor las usa para calcular, no las guarda en la consulta.
class SelectorDestino extends StatelessWidget {
  const SelectorDestino({super.key, required this.destinos, required this.onCambio, this.etiqueta = 'Ciudad de entrega'});
  final List<Destino> destinos;
  final VoidCallback onCambio;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final t = TiendaScope.of(context);
    final d = t.destino;
    final ciudadSeleccionada = d != null && !d.esUbicacion && destinos.any((x) => x.ciudad == d.ciudad) ? d.ciudad : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (d != null && d.esUbicacion)
        Container(
          key: const Key('ubicacion-activa'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: doomSuave, borderRadius: BorderRadius.circular(8), border: Border.all(color: doom.withValues(alpha: 0.4))),
          child: Row(children: [
            const Icon(Icons.my_location, color: doom, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (t.ubicacionInfo?.kmBodega != null) Text('≈ ${t.ubicacionInfo!.kmBodega} km de la bodega', style: const TextStyle(fontSize: 12, color: gris)),
              ]),
            ),
            IconButton(tooltip: 'Quitar', visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: () {
              t.elegirCiudad(null);
              onCambio();
            }),
          ]),
        )
      else
        DropdownButtonFormField<String>(
          key: const Key('destino'),
          initialValue: ciudadSeleccionada,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(labelText: etiqueta),
          items: [for (final x in destinos) DropdownMenuItem(value: x.ciudad, child: Text('${x.ciudad} · ${x.km} km'))],
          onChanged: (v) {
            t.elegirCiudad(v);
            onCambio();
          },
        ),
      const SizedBox(height: 6),
      TextButton.icon(
        key: const Key('usar-ubicacion'),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), alignment: Alignment.centerLeft),
        onPressed: t.localizando
            ? null
            : () async {
                final ok = await t.usarMiUbicacion();
                if (ok) onCambio();
              },
        icon: t.localizando ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 16),
        label: Text(t.localizando ? 'Buscando tu ubicación…' : 'Usar mi ubicación actual', style: const TextStyle(fontSize: 13)),
      ),
      if (t.errorUbicacion != null) Text(t.errorUbicacion!, key: const Key('error-ubicacion'), style: const TextStyle(color: Colors.red, fontSize: 12)),
    ]);
  }
}
