import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Información pública del negocio (fila de la tabla `negocios`).
///
/// Los clientes siempre ven estos datos; solo un `dueno` puede cambiarlos
/// desde el Panel del negocio (RLS en Supabase los protege).
class InfoNegocio {
  const InfoNegocio({
    required this.id,
    required this.nombre,
    required this.rubro,
    required this.direccion,
    required this.telefono,
    required this.whatsapp,
    required this.descripcion,
    required this.horario,
    required this.fotoUrl,
  });

  factory InfoNegocio.fromMap(Map<String, dynamic> map) => InfoNegocio(
        id: (map['id'] as num?)?.toInt() ?? 1,
        nombre: '${map['nombre'] ?? ''}'.trim(),
        rubro: '${map['rubro'] ?? 'Gastronomía'}',
        direccion: '${map['direccion'] ?? ''}',
        telefono: '${map['telefono'] ?? ''}',
        whatsapp: '${map['whatsapp'] ?? ''}',
        descripcion: '${map['descripcion'] ?? ''}',
        horario: '${map['horario'] ?? ''}',
        fotoUrl: '${map['foto_url'] ?? ''}',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'rubro': rubro,
        'direccion': direccion,
        'telefono': telefono,
        'whatsapp': whatsapp,
        'descripcion': descripcion,
        'horario': horario,
        'foto_url': fotoUrl,
      };

  /// Datos de respaldo (los mismos que había escritos en la app) por si
  /// Supabase no está configurado o el teléfono no tiene internet.
  static const actual = InfoNegocio(
    id: 1,
    nombre: 'Churrasquería El Fogón',
    rubro: 'Gastronomía',
    direccion: 'Av. Busch 1234, Santa Cruz de la Sierra',
    telefono: '+591 6775 6448',
    whatsapp: '+591 6775 6448',
    descripcion: 'Parrillas y platos tradicionales cruceños para compartir.',
    horario: 'Mar a Dom · 18:00 – 23:30',
    fotoUrl: '',
  );

  final int id;
  final String nombre;
  final String rubro;
  final String direccion;
  final String telefono;
  final String whatsapp;
  final String descripcion;
  final String horario;
  final String fotoUrl;

  /// Número pelado para wa.me / tel: (solo dígitos).
  String get numeroWa =>
      (whatsapp.isEmpty ? telefono : whatsapp).replaceAll(RegExp(r'[^0-9]'), '');

  InfoNegocio copyWith({
    String? nombre,
    String? direccion,
    String? telefono,
    String? whatsapp,
    String? descripcion,
    String? horario,
    String? fotoUrl,
  }) =>
      InfoNegocio(
        id: id,
        nombre: nombre ?? this.nombre,
        rubro: rubro,
        direccion: direccion ?? this.direccion,
        telefono: telefono ?? this.telefono,
        whatsapp: whatsapp ?? this.whatsapp,
        descripcion: descripcion ?? this.descripcion,
        horario: horario ?? this.horario,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );
}

/// Producto de la Churrasquería (fila de la tabla `productos`).
class Producto {  final String id;
  final String nombre;
  final String descripcion;
  final double precio;

  /// URL pública de la foto en Supabase Storage (cadena vacía = sin foto).
  final String fotoUrl;

  const Producto({
    this.id = '',
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.fotoUrl = '',
  });

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: '${map['id'] ?? ''}',
        nombre: '${map['nombre'] ?? ''}',
        descripcion: '${map['descripcion'] ?? ''}',
        precio: (map['precio'] as num?)?.toDouble() ?? 0,
        fotoUrl: '${map['imagen_url'] ?? ''}',
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
        'imagen_url': fotoUrl,
      };
}

/// Resultado de cargar el catálogo: los productos y si vienen
/// de la base de datos o del caché local (sin conexión).
class CatalogoResult {
  const CatalogoResult({
    required this.productos,
    required this.desdeCache,
    this.actualizado,
  });

  final List<Producto> productos;

  /// true cuando la base de datos no respondió y se usaron
  /// los productos guardados en el dispositivo (modo offline).
  final bool desdeCache;

  /// Fecha/hora de la última carga exitosa (desde el servidor
  /// o desde el caché guardado).
  final DateTime? actualizado;
}

const _claveCacheProductos = 'cache_productos_v1';
const _claveCacheFecha = 'cache_productos_fecha';
const _claveCacheNegocio = 'cache_negocio_v1';

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

  /// Rol del usuario en la tabla `perfiles`: `dueno` o `cliente`.
  /// Si no hay sesión, Supabase no responde o la fila no existe, devuelve
  /// `cliente` (el acceso más restrictivo: el panel queda oculto).
  static Future<String> rolActual() async {
    final c = _client;
    final id = usuario?.id;
    if (c == null || id == null) return 'cliente';
    try {
      final data = await c
          .from('perfiles')
          .select('rol')
          .eq('id', id)
          .maybeSingle();
      final rol = data?['rol'] as String?;
      return rol == 'dueno' ? 'dueno' : 'cliente';
    } catch (_) {
      return 'cliente';
    }
  }

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
      await prefs.setString(
          _claveCacheFecha, DateTime.now().toIso8601String());
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

  /// Lee la fecha/hora de la última carga exitosa (o null si no hay).
  static Future<DateTime?> _leerCacheFecha() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_claveCacheFecha);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------- información negocio

  /// Guarda la información pública del negocio en el dispositivo.
  static Future<void> _guardarCacheNegocio(InfoNegocio info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveCacheNegocio, jsonEncode(info.toMap()));
    } catch (_) {
      // El caché es un extra: cualquier fallo se ignora.
    }
  }

  /// Lee la información guardada en el dispositivo (o null si no hay).
  static Future<InfoNegocio?> _leerCacheNegocio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_claveCacheNegocio);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      return InfoNegocio.fromMap(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// Lee la información del negocio (fila con id 1, el de la actividad).
  /// Sin configurar o sin internet → caché local o datos de respaldo.
  static Future<InfoNegocio> cargarNegocio() async {
    final c = _client;
    if (c == null) {
      return await _leerCacheNegocio() ?? InfoNegocio.actual;
    }
    try {
      final row = await c
          .from('negocios')
          .select()
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return await _leerCacheNegocio() ?? InfoNegocio.actual;
      }
      final info = InfoNegocio.fromMap(Map<String, dynamic>.from(row));
      await _guardarCacheNegocio(info);
      return info;
    } catch (_) {
      return await _leerCacheNegocio() ?? InfoNegocio.actual;
    }
  }

  /// Lee las coordenadas de los negocios (para el mapa).
  /// Sin configurar o sin internet → lista vacía (el mapa usa el respaldo).
  static Future<List<Map<String, dynamic>>> cargarCoordenadas() async {
    final c = _client;
    if (c == null) return const [];
    try {
      final data = await c
          .from('negocios')
          .select('nombre, rubro, descripcion, latitud, longitud')
          .order('id', ascending: true);
      return (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Guarda los cambios hechos por el dueño en la información del negocio.
  /// La RLS permite el UPDATE solo a `dueno`; cualquier otro recibe error.
  static Future<void> actualizarNegocio(InfoNegocio info) async {
    final c = _clienteObligado();
    await c.from('negocios').update({
      'nombre': info.nombre,
      'direccion': info.direccion,
      'telefono': info.telefono,
      'whatsapp': info.whatsapp,
      'descripcion': info.descripcion,
      'horario': info.horario,
      'foto_url': info.fotoUrl,
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', info.id);
    await _guardarCacheNegocio(info);
  }

  /// Da de alta a otro dueño por su correo (RPC `agregar_dueno`).
  static Future<void> agregarDueno(String correo) async {
    final c = _clienteObligado();
    await c.rpc('agregar_dueno', params: {'p_email': correo.trim()});
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
      return CatalogoResult(
        productos: lista,
        desdeCache: false,
        actualizado: DateTime.now(),
      );
    } catch (_) {
      final cache = await _leerCache();
      if (cache != null && cache.isNotEmpty) {
        return CatalogoResult(
          productos: cache,
          desdeCache: true,
          actualizado: await _leerCacheFecha(),
        );
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

  // ------------------------------------------------------- panel negocio

  /// Registra el pedido y devuelve su número.
  ///
  /// Ese número es el que después identifica el cobro por QR, así que
  /// no se descarta: lo necesita `PagoQrPage`.
  static Future<int> enviarPedido({
    required String telefono,
    required String detalle,
    required double total,
  }) async {
    final c = _clienteObligado();
    // Usa la función SQL `crear_pedido` (BD_SQL/07_crear_pedido.sql):
    // valida los datos y registra el pedido en una sola transacción.
    final id = await c.rpc('crear_pedido', params: {
      'p_nombre': usuario?.userMetadata?['nombre'] ?? usuario?.email ?? '',
      'p_telefono': telefono,
      'p_detalle': detalle,
      'p_total': total,
    });
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.parse('$id');
  }

  /// Guarda la dirección de la foto de un plato.
  ///
  /// La RLS solo deja hacer este UPDATE a una cuenta con rol de dueño
  /// (política «productos: el dueno actualiza», script 11). Cualquier
  /// otra recibe un error del servidor, no una negativa de la app.
  static Future<void> actualizarFotoProducto({
    required String productoId,
    required String url,
  }) async {
    final c = _clienteObligado();

    // `.select()` devuelve las filas que el UPDATE tocó. Sin eso, si el
    // plato ya no existe —porque lo borraron mientras el catálogo estaba
    // abierto— Supabase no se queja: actualizar cero filas no es un
    // error para él, y la foto quedaría en el depósito sin que ningún
    // plato la apunte.
    final filas = await c
        .from('productos')
        .update({'imagen_url': url})
        .eq('id', productoId)
        .select('id');

    if ((filas as List).isEmpty) {
      throw StateError(
        'El plato ya no existe en el catálogo. Recargá la lista y '
        'volvé a intentarlo.',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> cargarReservas() async {
    final c = _clienteObligado();
    final data =
        await c.from('reservas').select().order('fecha', ascending: false).limit(50);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> cargarConsultas() async {
    final c = _clienteObligado();
    final data = await c
        .from('consultas')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> cargarPedidos() async {
    final c = _clienteObligado();
    final data = await c
        .from('pedidos')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> actualizarEstadoPedido(int id, String estado) async {
    final c = _clienteObligado();
    await c.from('pedidos').update({'estado': estado}).eq('id', id);
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

