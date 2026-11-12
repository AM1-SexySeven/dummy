import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Producto de la Churrasquería (fila de la tabla `productos`).
class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;

  const Producto({
    this.id = '',
    required this.nombre,
    required this.descripcion,
    required this.precio,
  });

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: '${map['id'] ?? ''}',
        nombre: '${map['nombre'] ?? ''}',
        descripcion: '${map['descripcion'] ?? ''}',
        precio: (map['precio'] as num?)?.toDouble() ?? 0,
      );

  /// Datos de ejemplo, usados cuando Supabase no está configurado.
  static const List<Producto> ejemplos = [
    Producto(
      nombre: 'Parrillada para dos',
      descripcion: 'Carne, chorizo, yuca y ensalada',
      precio: 120,
    ),
    Producto(
      nombre: 'Majadito batido',
      descripcion: 'Arroz con charque, huevo y plátano',
      precio: 35,
    ),
  ];

  /// Map para guardar el producto en el caché local (offline).
  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
      };
}

/// Resultado de cargar el catálogo: los productos y si vienen
/// de la base de datos o del caché local (sin conexión).
class CatalogoResult {
  const CatalogoResult({required this.productos, required this.desdeCache});

  final List<Producto> productos;

  /// true cuando la base de datos no respondió y se usaron
  /// los productos guardados en el dispositivo (modo offline).
  final bool desdeCache;
}

const _claveCacheProductos = 'cache_productos_v1';

/// Punto único de acceso a Supabase (auth + base de datos).
///
/// Si `SupabaseConfig.sinConfigurar` es true, [init] no hace nada y
/// [client] queda en null: la app entra en "modo demo" y sigue funcionando
/// con datos de ejemplo.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// true cuando Supabase terminó de inicializarse
  /// (o cuando no está configurado: la app entra en «modo demo»).
  static final ValueNotifier<bool> listo =
      ValueNotifier<bool>(SupabaseConfig.sinConfigurar);

  /// Cliente de Supabase, o null si no está configurado/Inicializado.
  static SupabaseClient? get client => _client;

  /// true cuando hay conexión real con Supabase.
  static bool get disponible => _client != null;

  /// true cuando hay un usuario con sesión iniciada.
  static bool get haySesion => _client?.auth.currentSession != null;

  /// Usuario con sesión (null si no hay sesión o no hay Supabase).
  static User? get usuario => _client?.auth.currentSession?.user;

  /// Llamar desde `main()` sin esperarla: la app muestra la bienvenida
  /// de inmediato y [listo] avisa cuando el cliente está disponible.
  static Future<void> init() async {
    if (SupabaseConfig.sinConfigurar) {
      listo.value = true;
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    _client = Supabase.instance.client;
    listo.value = true;
  }

  // ---------------------------------------------------------------- auth

  static Future<void> iniciarSesion({
    required String correo,
    required String clave,
  }) async {
    final c = _client;
    if (c == null) throw const AuthException('Supabase no está configurado');
    await c.auth.signInWithPassword(email: correo, password: clave);
  }

  static Future<void> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    final c = _client;
    if (c == null) throw const AuthException('Supabase no está configurado');
    await c.auth.signUp(
      email: correo,
      password: clave,
      data: {'nombre': nombre},
    );
  }

  static Future<void> cerrarSesion() async => _client?.auth.signOut();

  // ------------------------------------------------------------ productos

  /// Guarda los productos en el dispositivo (para el modo offline).
  static Future<void> _guardarCache(List<Producto> productos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = productos.map((p) => p.toMap()).toList();
      await prefs.setString(_claveCacheProductos, jsonEncode(json));
    } catch (_) {
      // El caché es un extra: cualquier fallo se ignora.
    }
  }

  /// Lee los productos guardados en el dispositivo (o null si no hay).
  static Future<List<Producto>?> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_claveCacheProductos);
      if (raw == null) return null;
      final lista = jsonDecode(raw) as List;
      return lista
          .map((e) => Producto.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Carga los productos desde Supabase.
  /// Sin configurar → devuelve los datos de ejemplo.
  /// Si la base de datos no responde → devuelve el caché local si existe
  /// (`desdeCache: true`) o lanza la excepción (error en pantalla).
  static Future<CatalogoResult> cargarProductos() async {
    final c = _client;
    if (c == null) {
      return const CatalogoResult(productos: Producto.ejemplos, desdeCache: false);
    }

    try {
      final data = await c.from('productos').select().order('created_at');
      final lista = (data as List)
          .map((fila) => Producto.fromMap(Map<String, dynamic>.from(fila as Map)))
          .toList();
      await _guardarCache(lista);
      return CatalogoResult(productos: lista, desdeCache: false);
    } catch (_) {
      final cache = await _leerCache();
      if (cache != null && cache.isNotEmpty) {
        return CatalogoResult(productos: cache, desdeCache: true);
      }
      rethrow;
    }
  }

  static Future<void> agregarProducto({
    required String nombre,
    required String descripcion,
    required double precio,
  }) async {
    final c = _clienteObligado();
    await c.from('productos').insert({
      'negocio': 'Churrasquería El Fogón',
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
    });
  }

  // ----------------------------------------------------------- consultas

  static Future<void> enviarConsulta({required String mensaje}) async {
    final c = _clienteObligado();
    await c.from('consultas').insert({
      'user_id': usuario!.id,
      'nombre': usuario?.userMetadata?['nombre'] ?? usuario?.email ?? '',
      'mensaje': mensaje,
      'estado': 'pendiente',
    });
  }

  // ------------------------------------------------------------- reservas

  static Future<void> enviarReserva({
    required DateTime fecha,
    required int personas,
    required String detalle,
  }) async {
    final c = _clienteObligado();
    await c.from('reservas').insert({
      'user_id': usuario!.id,
      'nombre': usuario?.userMetadata?['nombre'] ?? usuario?.email ?? '',
      'fecha': fecha.toIso8601String().split('T').first,
      'personas': personas,
      'detalle': detalle,
      'estado': 'pendiente',
    });
  }

  static SupabaseClient _clienteObligado() {
    final c = _client;
    if (c == null) {
      throw const AuthException(
        'Supabase no está configurado. Edita lib/config.dart',
      );
    }
    if (usuario == null) {
      throw const AuthException('Debes iniciar sesión primero');
    }
    return c;
  }
}
