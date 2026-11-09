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
}

/// Punto único de acceso a Supabase (auth + base de datos).
///
/// Si `SupabaseConfig.sinConfigurar` es true, [init] no hace nada y
/// [client] queda en null: la app entra en "modo demo" y sigue funcionando
/// con datos de ejemplo.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// Cliente de Supabase, o null si no está configurado/Inicializado.
  static SupabaseClient? get client => _client;

  /// true cuando hay conexión real con Supabase.
  static bool get disponible => _client != null;

  /// true cuando hay un usuario con sesión iniciada.
  static bool get haySesion => _client?.auth.currentSession != null;

  /// Usuario con sesión (null si no hay sesión o no hay Supabase).
  static User? get usuario => _client?.auth.currentSession?.user;

  /// Llamar una sola vez desde `main()` antes de `runApp`.
  static Future<void> init() async {
    if (SupabaseConfig.sinConfigurar) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    _client = Supabase.instance.client;
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

  /// Carga los productos desde Supabase.
  /// Sin configurar → devuelve los datos de ejemplo.
  static Future<List<Producto>> cargarProductos() async {
    final c = _client;
    if (c == null) return Producto.ejemplos;

    final data = await c.from('productos').select().order('created_at');
    return (data as List)
        .map((fila) => Producto.fromMap(fila as Map<String, dynamic>))
        .toList();
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
