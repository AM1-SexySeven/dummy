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
  static ThemeData get temaClaro => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB33A1A), // brasas / rojo parrilla
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  /// Tema Oscuro (Dark Theme) con estética nocturna de churrasquería.
  static ThemeData get temaOscuro => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB33A1A), // brasas / rojo parrilla
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
