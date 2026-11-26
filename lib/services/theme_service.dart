import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para controlar y persistir el tema de la aplicación (Claro / Oscuro / Sistema).
class ThemeService {
  ThemeService._();

  static const String _claveTema = 'modo_tema_pref_v1';

  /// Notificador del modo actual (escuchado por MaterialApp).
  static final ValueNotifier<ThemeMode> modoTema =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Carga la preferencia guardada en SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_claveTema);
      if (guardado == 'oscuro') {
        modoTema.value = ThemeMode.dark;
      } else if (guardado == 'claro') {
        modoTema.value = ThemeMode.light;
      } else {
        modoTema.value = ThemeMode.system;
      }
    } catch (_) {
      modoTema.value = ThemeMode.system;
    }
  }

  /// Cambia el modo de tema y guarda la preferencia en el dispositivo.
  static Future<void> cambiarModo(ThemeMode nuevoModo) async {
    modoTema.value = nuevoModo;
    try {
      final prefs = await SharedPreferences.getInstance();
      String valor = 'sistema';
      if (nuevoModo == ThemeMode.dark) valor = 'oscuro';
      if (nuevoModo == ThemeMode.light) valor = 'claro';
      await prefs.setString(_claveTema, valor);
    } catch (_) {}
  }

  /// Tema Claro (Light Theme) con colores de brasas/parrilla.
  // ------------------------------------------------------------------
  //  Paleta
  // ------------------------------------------------------------------
  //  La comida pone el color: el fondo es blanco y el texto carbón tibio.
  //  El naranja brasa hace una sola cosa, la plata y la acción principal;
  //  si apareciera en todos lados dejaría de significar algo.

  /// Carbón tibio. Texto y fondos oscuros.
  static const Color tinta = Color(0xFF14100E);

  /// Gris cálido. Texto secundario.
  static const Color humo = Color(0xFF6B625B);

  /// Naranja brasa. SOLO precios y acción principal.
  static const Color brasa = Color(0xFFE8420E);

  /// Verde monte. SOLO el estado «pagado».
  static const Color monte = Color(0xFF1F5132);

  /// Ámbar. SOLO la cuenta regresiva del QR.
  static const Color llama = Color(0xFFFFC24B);

  /// Líneas y separadores.
  static const Color linea = Color(0xFFE6E1DA);
  static const Color lineaOscura = Color(0xFF2C2724);

  /// Fondo tenue para avisos.
  static const Color papelTenue = Color(0xFFF4F1EC);

  static const String display = 'Bricolage';
  static const String texto = 'Hanken';

  static TextTheme _tipografia(Color base, Color suave) => TextTheme(
        // Nombres de plato y títulos: afiche, no etiqueta.
        displayLarge: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w800,
            fontSize: 40, height: 0.96, letterSpacing: -1.4, color: base),
        headlineLarge: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w800,
            fontSize: 28, height: 0.98, letterSpacing: -0.9, color: base),
        headlineMedium: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w600,
            fontSize: 22, height: 1.05, letterSpacing: -0.6, color: base),
        titleLarge: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w600,
            fontSize: 17, height: 1.1, letterSpacing: -0.35, color: base),
        // Todo lo funcional.
        bodyLarge: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w400,
            fontSize: 15.5, height: 1.5, color: base),
        bodyMedium: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w400,
            fontSize: 14, height: 1.45, color: suave),
        bodySmall: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w400,
            fontSize: 12.5, height: 1.4, color: suave),
        labelLarge: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w600,
            fontSize: 15, height: 1, color: base),
        labelMedium: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w500,
            fontSize: 13, height: 1, color: suave),
      );

  static ThemeData _armar({required bool oscuro}) {
    final fondo = oscuro ? tinta : Colors.white;
    final base = oscuro ? Colors.white : tinta;
    final suave = oscuro ? const Color(0xFFA79F98) : humo;
    final borde = oscuro ? lineaOscura : linea;

    return ThemeData(
      useMaterial3: true,
      brightness: oscuro ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: fondo,
      canvasColor: fondo,
      fontFamily: texto,
      colorScheme: ColorScheme(
        brightness: oscuro ? Brightness.dark : Brightness.light,
        primary: brasa,
        onPrimary: Colors.white,
        secondary: tinta,
        onSecondary: Colors.white,
        tertiary: monte,
        onTertiary: Colors.white,
        error: brasa,
        onError: Colors.white,
        surface: fondo,
        onSurface: base,
        surfaceContainerHighest: oscuro ? const Color(0xFF1E1916) : papelTenue,
        outline: borde,
        outlineVariant: borde,
      ),
      textTheme: _tipografia(base, suave),
      dividerTheme: DividerThemeData(color: borde, thickness: 1, space: 1),
      // Esquinas rectas en todo: la foto y la tipografía estructuran la
      // pantalla, no las cajitas redondeadas.
      cardTheme: CardThemeData(
        color: fondo,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borde),
          borderRadius: BorderRadius.zero,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: base,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w800,
            fontSize: 23, letterSpacing: -0.7, color: base),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brasa,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
              fontFamily: texto, fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base,
          minimumSize: const Size.fromHeight(46),
          side: BorderSide(color: borde, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
              fontFamily: texto, fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: base,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
              fontFamily: texto, fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fondo,
        selectedColor: base,
        side: BorderSide(color: borde),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        labelStyle: TextStyle(
            fontFamily: texto, fontWeight: FontWeight.w600,
            fontSize: 13.5, color: base),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borde, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borde, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: base, width: 1.5),
        ),
        hintStyle: TextStyle(fontFamily: texto, fontSize: 15, color: suave),
        labelStyle: TextStyle(fontFamily: texto, fontSize: 14, color: suave),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tinta,
        contentTextStyle: const TextStyle(
            fontFamily: texto, fontSize: 14.5, color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fondo,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: TextStyle(
            fontFamily: display, fontWeight: FontWeight.w800,
            fontSize: 21, letterSpacing: -0.5, color: base),
        contentTextStyle: TextStyle(
            fontFamily: texto, fontSize: 15, height: 1.45, color: suave),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: fondo,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textColor: base,
        iconColor: base,
      ),
    );
  }

  /// Tema claro: blanco, para que la comida ponga el color.
  static ThemeData get temaClaro => _armar(oscuro: false);

  /// Tema oscuro: el mismo sistema sobre carbón tibio.
  static ThemeData get temaOscuro => _armar(oscuro: true);
}
