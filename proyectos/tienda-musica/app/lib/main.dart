import 'package:flutter/material.dart';

import 'api.dart';
import 'pages/home_page.dart';
import 'state.dart';
import 'ubicacion.dart';
import 'theme.dart';

void main() => runApp(const TiendaApp());

class TiendaApp extends StatefulWidget {
  const TiendaApp({super.key, this.api, this.ubicacion});
  final RumboApi? api;
  final ServicioUbicacion? ubicacion;

  @override
  State<TiendaApp> createState() => _TiendaAppState();
}

class _TiendaAppState extends State<TiendaApp> {
  late final Tienda tienda = Tienda(widget.api ?? RumboApi(), ubicacion: widget.ubicacion);

  @override
  Widget build(BuildContext context) {
    return TiendaScope(
      tienda: tienda,
      child: MaterialApp(
        title: 'Tesitura · Música e instrumentos',
        debugShowCheckedModeBanner: false,
        theme: construirTema(),
        home: const HomePage(),
      ),
    );
  }
}
