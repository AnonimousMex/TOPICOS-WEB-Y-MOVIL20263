import 'package:flutter/material.dart';

import 'api.dart';
import 'configuracion_servidor.dart';
import 'pages/home_page.dart';
import 'state.dart';
import 'ubicacion.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configuracion = ConfiguracionServidor();
  final url = await configuracion.cargar();
  runApp(TiendaApp(api: RumboApi(baseUrl: url), alCambiarServidor: configuracion.guardar, almacen: AlmacenSesion()));
}

class TiendaApp extends StatefulWidget {
  const TiendaApp({super.key, this.api, this.ubicacion, this.alCambiarServidor, this.almacen});
  final AlmacenSesion? almacen;
  final RumboApi? api;
  final ServicioUbicacion? ubicacion;
  final Future<void> Function(String)? alCambiarServidor;

  @override
  State<TiendaApp> createState() => _TiendaAppState();
}

class _TiendaAppState extends State<TiendaApp> {
  late final Tienda tienda = Tienda(widget.api ?? RumboApi(), ubicacion: widget.ubicacion, alCambiarServidor: widget.alCambiarServidor, almacen: widget.almacen);

  @override
  void initState() {
    super.initState();
    tienda.restaurarSesion();
  }

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
