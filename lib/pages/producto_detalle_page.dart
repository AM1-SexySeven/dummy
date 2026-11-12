import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

/// Pantalla de detalle de un plato del catálogo.
///
/// Consultar/Reservar devuelven el resultado (`consultar` / `reservar`)
/// al catálogo, que decide pedir sesión antes de abrir el formulario.
class ProductoDetallePage extends StatelessWidget {
  const ProductoDetallePage({super.key, required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precio =
        'Bs ${producto.precio.toStringAsFixed(2).replaceAll('.', ',')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del plato'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                producto.nombre,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: const Text('Gastronomía'),
                  avatar: const Icon(Icons.restaurant_rounded, size: 18),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Descripción',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                producto.descripcion.isEmpty
                    ? 'Plato de la casa.'
                    : producto.descripcion,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Precio',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        precio,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Estas consultas devuelven el resultado al catálogo
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'consultar'),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Consultar sobre este plato'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'reservar'),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Reservar para comer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
