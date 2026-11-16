import 'package:flutter/material.dart';

// Paleta: acero oscuro y verde. Tema oscuro.
const acero = Color(0xFF080C0E); // encabezado y pie
const aceroMedio = Color(0xFF2A343A);
const superficie = Color(0xFF141A1E); // tarjetas
const superficieAlta = Color(0xFF1C252A); // campos, chips, paneles elevados
const bordeSutil = Color(0x2E9FB4BC); // filetes metálicos
const doom = Color(0xFF1B8F5A); // verde de acción (botones, selección)
const doomClaro = Color(0xFF34D17F); // enlaces y textos de acento sobre fondo oscuro
const doomBrillo = Color(0xFF3BE08F); // destellos: el brillo de los ojos de la máscara
const doomSuave = Color(0xFF12302A); // fondos suaves de acción
const doomOscuro = Color(0xFF06231A); // franja de anuncio y degradados
const verde = Color(0xFF2FD181); // ahorro: descuentos y envío gratis
const fondo = Color(0xFF0C1114);
const tinta = Color(0xFFE8EEEC);
const gris = Color(0xFFA2AEB4);
const grisClaro = Color(0xFF7C8A91);

const ambar = Color(0xFFE8A33D);
const crema = superficieAlta; // nombre heredado de la versión clara

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(seedColor: doom, brightness: Brightness.dark).copyWith(
    primary: doomClaro,
    onPrimary: acero,
    secondary: doomBrillo,
    surface: superficie,
    onSurface: tinta,
    surfaceContainerHighest: superficieAlta,
    outline: bordeSutil,
    error: const Color(0xFFFF6B6B),
  );
  final bisel = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: bordeSutil));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    pageTransitionsTheme: PageTransitionsTheme(builders: {for (final p in TargetPlatform.values) p: const _TransicionSuave()}),
    colorScheme: esquema,
    scaffoldBackgroundColor: fondo,
    canvasColor: superficie,
    hoverColor: doomBrillo.withValues(alpha: 0.07),
    textTheme: Typography.whiteMountainView.apply(bodyColor: tinta, displayColor: tinta),
    appBarTheme: const AppBarTheme(
      backgroundColor: acero,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: bordeSutil)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: superficieAlta, shape: bisel),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficieAlta,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: gris),
      hintStyle: const TextStyle(color: grisClaro),
      border: borde,
      enabledBorder: borde,
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: doomBrillo, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: doom,
        foregroundColor: Colors.white,
        disabledBackgroundColor: superficieAlta,
        disabledForegroundColor: grisClaro,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: doomClaro,
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: doomBrillo.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: doomClaro)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: tinta)),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: bordeSutil)),
      side: const BorderSide(color: bordeSutil),
      backgroundColor: superficieAlta,
      selectedColor: doom,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: tinta),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? doomBrillo : gris),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? doom : superficieAlta),
    ),
    snackBarTheme: SnackBarThemeData(backgroundColor: superficieAlta, contentTextStyle: const TextStyle(color: tinta), shape: bisel, behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: bordeSutil, space: 1),
    tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: superficieAlta, border: Border.all(color: bordeSutil))),
  );
}

class Categoria {
  const Categoria(this.etiqueta, this.icono, this.color);
  final String etiqueta;
  final IconData icono;
  final Color color;
}

const categorias = <String, Categoria>{
  'guitarra': Categoria('Guitarras y bajos', Icons.queue_music, Color(0xFFB4533C)),
  'teclado': Categoria('Teclados y pianos', Icons.piano, Color(0xFF3F5E8C)),
  'percusion': Categoria('Batería y percusión', Icons.album, Color(0xFF8A5A9B)),
  'viento': Categoria('Viento', Icons.air, Color(0xFF3E8E7E)),
  'cuerda_frotada': Categoria('Cuerdas', Icons.graphic_eq, Color(0xFFC0823A)),
  'accesorio': Categoria('Audio y accesorios', Icons.tune, Color(0xFF5F6B73)),
};

Categoria categoriaDe(String clave) => categorias[clave] ?? const Categoria('Otros', Icons.music_note, Color(0xFF5F6B73));

class Nivel {
  const Nivel(this.etiqueta, this.icono, this.color, this.resumen);
  final String etiqueta, resumen;
  final IconData icono;
  final Color color;
}

const niveles = <String, Nivel>{
  'basico': Nivel('Básico', Icons.inventory_2_outlined, Color(0xFF3BE08F), 'Caja con relleno'),
  'reforzado': Nivel('Reforzado', Icons.shield_outlined, Color(0xFFE8A33D), 'Caja doble + seguro parcial'),
  'premium': Nivel('Premium', Icons.verified_user_outlined, Color(0xFFB07CFF), 'Estuche rígido + seguro total'),
};

Nivel nivelDe(String clave) => niveles[clave] ?? niveles['basico']!;

String dinero(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '\$$b';
}


/// Duraciones y curvas de toda la app: cortas y con salida suave, para que nada se sienta brusco ni lento.
class Anim {
  static const rapida = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const curva = Curves.easeOutCubic;
}

/// Transición entre pantallas: aparece con un fundido y sube apenas un poco.
class _TransicionSuave extends PageTransitionsBuilder {
  const _TransicionSuave();

  @override
  Duration get transitionDuration => Anim.normal;

  @override
  Duration get reverseTransitionDuration => Anim.rapida;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final a = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(a), child: child),
    );
  }
}
