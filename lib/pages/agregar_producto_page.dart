import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';
import '../services/supabase_service.dart';

/// Pantalla para añadir un plato/producto al negocio.
class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  String _categoriaSeleccionada = 'Parrillas';
  ImageSource? _origenFoto;
  XFile? _fotoSeleccionada;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirOrigenFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Foto inicial del plato',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: origen,
      maxWidth: StorageService.anchoMaximo,
      imageQuality: StorageService.calidad,
    );

    if (foto != null) {
      setState(() {
        _origenFoto = origen;
        _fotoSeleccionada = foto;
      });
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final precio = double.tryParse(_precioCtrl.text.trim().replaceAll(',', '.'));

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingrese el nombre del plato');
      return;
    }
    if (precio == null || precio <= 0) {
      setState(() => _error = 'Ingrese un precio válido (ej: 45.50)');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final productoMap = await SupabaseService.agregarProducto(
        nombre: nombre,
        descripcion: desc.isEmpty ? 'Plato de Churrasquería El Fogón' : desc,
        precio: precio,
        categoria: _categoriaSeleccionada,
      );

      final productoId = '${productoMap['id'] ?? ''}';

      if (_origenFoto != null && productoId.isNotEmpty && SupabaseService.disponible) {
        final subida = await StorageService.subirFotoPlato(
          productoId: productoId,
          origen: _origenFoto!,
        );
        if (subida.ok && subida.url != null) {
          await SupabaseService.actualizarFotoProducto(
            productoId: productoId,
            url: subida.url!,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plato «$nombre» añadido al negocio')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo añadir el plato: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir plato'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.restaurant_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Nuevo plato del menú',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Se añadirá a Churrasquería El Fogón',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plato',
                  hintText: 'Ej: Pique macho',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Carne, papas fritas, huevo y llajua',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _precioCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio (Bs)',
                  hintText: 'Ej: 45.50',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría gastronómica',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Parrillas', child: Text('🔥 Parrillas')),
                  DropdownMenuItem(value: 'Platos Típicos', child: Text('🍛 Platos Típicos')),
                  DropdownMenuItem(value: 'Guarniciones', child: Text('🥗 Guarniciones')),
                  DropdownMenuItem(value: 'Bebidas', child: Text('🥤 Bebidas')),
                  DropdownMenuItem(value: 'Postres', child: Text('🍨 Postres')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _categoriaSeleccionada = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _guardando ? null : _elegirOrigenFoto,
                icon: Icon(
                  _fotoSeleccionada != null
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_a_photo_outlined,
                  color: _fotoSeleccionada != null ? Colors.green : null,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _fotoSeleccionada != null
                        ? 'Foto seleccionada (se subirá al guardar)'
                        : 'Seleccionar foto inicial (opcional)',
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.add_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Añadir plato', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _guardando ? null : () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
