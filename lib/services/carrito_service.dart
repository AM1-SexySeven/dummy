import 'package:flutter/foundation.dart';

/// Ítem del carrito: un producto con su cantidad.
class ItemCarrito {
  ItemCarrito({
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
  });

  final String nombre;
  final double precio;
  int cantidad;

  double get subtotal => precio * cantidad;
}

/// Carrito «Mi pedido» compartido entre pantallas.
///
/// Vive en memoria (se vacía al cerrar la app) y notifica sus cambios
/// con un [ValueNotifier] para que el contador del AppBar y la
/// pantalla del pedido se actualicen solos.
class Carrito extends ValueNotifier<List<ItemCarrito>> {
  Carrito._() : super(const []);

  static final Carrito instancia = Carrito._();

  /// Agrega un plato; si ya estaba, suma una unidad más.
  void agregar({required String nombre, required double precio}) {
    final items = List<ItemCarrito>.from(value);
    final i = items.indexWhere((e) => e.nombre == nombre);
    if (i == -1) {
      items.add(ItemCarrito(nombre: nombre, precio: precio));
    } else {
      items[i].cantidad += 1;
    }
    value = items;
  }

  /// Suma o resta una unidad; al llegar a cero lo quita.
  void cambiarCantidad(String nombre, int delta) {
    final items = List<ItemCarrito>.from(value);
    final i = items.indexWhere((e) => e.nombre == nombre);
    if (i == -1) return;
    items[i].cantidad += delta;
    if (items[i].cantidad <= 0) items.removeAt(i);
    value = items;
  }

  void quitar(String nombre) {
    value = value.where((e) => e.nombre != nombre).toList();
  }

  void vaciar() => value = const [];

  /// Total en bolivianos.
  double get total => value.fold(0, (s, e) => s + e.subtotal);

  /// Cantidad total de platos (para el badge del AppBar).
  int get cantidadTotal => value.fold(0, (s, e) => s + e.cantidad);

  /// Ej.: «2x Parrillada para dos, 1x Sonso asado» (para guardar el pedido).
  String get detalle =>
      value.map((e) => '${e.cantidad}x ${e.nombre}').join(', ');
}
