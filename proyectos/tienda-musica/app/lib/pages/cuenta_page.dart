import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/comunes.dart';
import '../widgets/logo.dart';
import '../widgets/marco.dart';
import 'compra_page.dart';

/// Inicio de sesión y registro. Al terminar con éxito se cierra y devuelve `true`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.registro = false});
  final bool registro;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool _registro = widget.registro;
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false, _ver = false;
  String? _error;
  Map<String, String> _campos = {};

  Future<void> _enviar() async {
    final t = TiendaScope.leer(context);
    setState(() {
      _cargando = true;
      _error = null;
      _campos = {};
    });
    try {
      final correo = _correo.text.trim().toLowerCase();
      _registro ? await t.registrarse(_nombre.text.trim(), correo, _clave.text) : await t.iniciarSesion(correo, _clave.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _campos = e.campos;
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _correo.text.contains('@') && _clave.text.length >= 8 && (!_registro || _nombre.text.trim().length >= 2) && !_cargando;
    return Marco(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(12), border: Border.all(color: bordeSutil)),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: LogoTesitura(tam: 64)),
                const SizedBox(height: 12),
                Text(_registro ? 'Crea tu cuenta' : 'Inicia sesión', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Necesitas una cuenta para pagar, ver tus compras y que el asistente consulte tus pedidos.', textAlign: TextAlign.center, style: TextStyle(color: gris, fontSize: 12.5)),
                const SizedBox(height: 18),
                AnimatedSize(
                  duration: Anim.normal,
                  curve: Anim.curva,
                  child: _registro
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(key: const Key('login-nombre'), controller: _nombre, onChanged: (_) => setState(() {}), textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Nombre', errorText: _campos['nombre'])),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                TextField(key: const Key('login-correo'), controller: _correo, onChanged: (_) => setState(() {}), keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: InputDecoration(labelText: 'Correo', prefixIcon: const Icon(Icons.mail_outline, size: 20), errorText: _campos['correo'])),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('login-clave'),
                  controller: _clave,
                  obscureText: !_ver,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => listo ? _enviar() : null,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText: _registro ? '8 o más caracteres con mayúscula, minúscula y número' : null,
                    errorText: _campos['contrasena'],
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(icon: Icon(_ver ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _ver = !_ver)),
                  ),
                ),
                if (_error != null && _campos.isEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, key: const Key('error-login'), style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13))),
                const SizedBox(height: 18),
                FilledButton(key: const Key('login-enviar'), onPressed: listo ? _enviar : null, child: _cargando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_registro ? 'Crear cuenta' : 'Entrar')),
                const SizedBox(height: 6),
                TextButton(
                  key: const Key('login-cambiar'),
                  onPressed: () => setState(() {
                    _registro = !_registro;
                    _error = null;
                    _campos = {};
                  }),
                  child: Text(_registro ? 'Ya tengo cuenta · Iniciar sesión' : '¿Eres nuevo? Crea tu cuenta'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compras de la cuenta iniciada, con el folio de cada pedido.
class MisComprasPage extends StatefulWidget {
  const MisComprasPage({super.key});

  @override
  State<MisComprasPage> createState() => _MisComprasPageState();
}

class _MisComprasPageState extends State<MisComprasPage> {
  List<CompraResumen>? _compras;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final c = await TiendaScope.leer(context).api.misCompras();
      if (mounted) setState(() => _compras = c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Marco(
      child: _error != null
          ? SingleChildScrollView(child: ErrorConReintento(mensaje: _error!, onReintentar: _cargar))
          : _compras == null
              ? const Center(child: CircularProgressIndicator())
              : _compras!.isEmpty
                  ? const Center(child: Text('Aún no tienes compras.', style: TextStyle(color: gris)))
                  : Centrado(
                      child: ListView(padding: const EdgeInsets.all(12), children: [
                        const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Mis compras', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
                        for (final c in _compras!)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: superficie, borderRadius: BorderRadius.circular(10), border: Border.all(color: bordeSutil)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(c.referencia, style: const TextStyle(fontWeight: FontWeight.w700))), Text(dinero(c.total), style: const TextStyle(fontWeight: FontWeight.w700))]),
                              if (c.destino.isNotEmpty) Text('Destino: ${c.destino}', style: const TextStyle(color: gris, fontSize: 12.5)),
                              const SizedBox(height: 6),
                              for (final p in c.pedidos)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${p.producto ?? 'Producto'} × ${p.cantidad}'),
                                  subtitle: Text('Folio ${p.folio} · ${nivelDe(p.recomendacion.nivelFinal).etiqueta}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompraPage(pedidos: [p], cliente: ''))),
                                ),
                            ]),
                          ),
                      ]),
                    ),
    );
  }
}

/// Bitácora de auditoría: quién hizo qué. Solo la ve el administrador (el servidor responde 403 a los demás).
class BitacoraPage extends StatefulWidget {
  const BitacoraPage({super.key});

  @override
  State<BitacoraPage> createState() => _BitacoraPageState();
}

class _BitacoraPageState extends State<BitacoraPage> {
  List<RegistroAuditoria>? _filas;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final f = await TiendaScope.leer(context).api.auditoria();
      if (mounted) setState(() => _filas = f);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Marco(
      child: _error != null
          ? SingleChildScrollView(child: ErrorConReintento(mensaje: _error!, onReintentar: _cargar))
          : _filas == null
              ? const Center(child: CircularProgressIndicator())
              : Centrado(
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('Bitácora de auditoría', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Escrituras y errores de la API. Nunca se guardan contraseñas ni tarjetas.', style: TextStyle(color: gris, fontSize: 12.5))),
                    for (final f in _filas!)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text('${f.status}', style: TextStyle(fontWeight: FontWeight.w700, color: f.status >= 400 ? const Color(0xFFFF6B6B) : verde)),
                        title: Text('${f.metodo} ${f.ruta}'),
                        subtitle: Text('${f.usuario.isEmpty ? 'anónimo' : f.usuario}${f.rol.isEmpty ? '' : ' (${f.rol})'} · ${f.ip} · ${f.fecha.substring(0, 19).replaceFirst('T', ' ')}'),
                      ),
                  ]),
                ),
    );
  }
}
