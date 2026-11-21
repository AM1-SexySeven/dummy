import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/supabase_service.dart';

/// Un punto marcado en el mapa de negocios de Santa Cruz.
class _NegocioMapa {
  const _NegocioMapa({
    required this.nombre,
    required this.rubro,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.icono,
    this.esNosotros = false,
  });

  final String nombre;
  final String rubro;
  final String descripcion;
  final double latitud;
  final double longitud;
  final IconData icono;
  final bool esNosotros;

  LatLng get punto => LatLng(latitud, longitud);
}

/// Mapa de negocios de la ciudad (OpenStreetMap, gratis, sin API key).
///
/// Muestra los puntos guardados en la tabla `negocios` de Supabase
/// (hoy: los 7 de la actividad). Si Supabase no responde, el mapa usa
/// una copia local de respaldo. Al tocar un marcador se ve su ficha.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  late final Future<List<_NegocioMapa>> _negocios = _cargar();

  Future<List<_NegocioMapa>> _cargar() async {
    final filas = await SupabaseService.cargarCoordenadas();
    if (filas.isEmpty) return _respaldo;
    return [
      for (final f in filas)
        _NegocioMapa(
          nombre: '${f['nombre'] ?? ''}',
          rubro: '${f['rubro'] ?? ''}',
          descripcion: '${f['descripcion'] ?? ''}',
          latitud: (f['latitud'] as num?)?.toDouble() ?? -17.7833,
          longitud: (f['longitud'] as num?)?.toDouble() ?? -63.1821,
          icono: _iconoPara('${f['rubro'] ?? ''}'),
          esNosotros: '${f['nombre'] ?? ''}'.contains('Fogón'),
        ),
    ];
  }

  static IconData _iconoPara(String rubro) {
    switch (rubro.toLowerCase()) {
      case 'gastronomía':
      case 'gastronomia':
        return Icons.restaurant_rounded;
      case 'artesanía':
      case 'artesania':
        return Icons.palette_rounded;
      case 'turismo':
        return Icons.tour_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  /// Respaldo local: los mismos negocios que trae la tabla `negocios`.
  static const List<_NegocioMapa> _respaldo = [
    _NegocioMapa(
      nombre: 'Churrasquería El Fogón',
      rubro: 'Gastronomía',
      descripcion: 'Parrillas y platos cruceños. Av. Busch 1234.',
      latitud: -17.7925,
      longitud: -63.1780,
      icono: Icons.restaurant_rounded,
      esNosotros: true,
    ),
    _NegocioMapa(
      nombre: 'Café Plaza 24 de Septiembre',
      rubro: 'Gastronomía',
      descripcion: 'Café de altura y cuñapés frente a la plaza principal.',
      latitud: -17.7839,
      longitud: -63.1822,
      icono: Icons.restaurant_rounded,
    ),
    _NegocioMapa(
      nombre: 'Salteñería Doña Rosa',
      rubro: 'Gastronomía',
      descripcion: 'Salteñas de carne y pollo, horneadas cada mañana.',
      latitud: -17.7755,
      longitud: -63.1910,
      icono: Icons.restaurant_rounded,
    ),
    _NegocioMapa(
      nombre: 'Cerámica del Oriente',
      rubro: 'Artesanía',
      descripcion: 'Jarras, tazas y piezas decorativas artesanales.',
      latitud: -17.7702,
      longitud: -63.1720,
      icono: Icons.palette_rounded,
    ),
    _NegocioMapa(
      nombre: 'Telares Chiquitanos',
      rubro: 'Artesanía',
      descripcion: 'Aguayos, mochilas y tejidos hechos a mano.',
      latitud: -17.7990,
      longitud: -63.1950,
      icono: Icons.palette_rounded,
    ),
    _NegocioMapa(
      nombre: 'Ruta Misionera',
      rubro: 'Turismo',
      descripcion: 'Circuito guiado por las misiones jesuíticas.',
      latitud: -17.7610,
      longitud: -63.2050,
      icono: Icons.tour_rounded,
    ),
    _NegocioMapa(
      nombre: 'Amboró Aventura Tours',
      rubro: 'Turismo',
      descripcion: 'Excursiones de un día al Parque Nacional Amboró.',
      latitud: -17.8050,
      longitud: -63.1650,
      icono: Icons.landscape_rounded,
    ),
  ];

  void _mostrarFicha(BuildContext context, _NegocioMapa n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: n.esNosotros
                      ? const Color(0xFFB33A1A)
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    n.icono,
                    color: n.esNosotros
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        n.rubro,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(n.descripcion),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const centro = LatLng(-17.7833, -63.1821);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de negocios'),
        centerTitle: true,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: centro,
          initialZoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'bo.edu.upds.conecta_cruz',
          ),
          FutureBuilder<List<_NegocioMapa>>(
            future: _negocios,
            builder: (context, snap) {
              final negocios = snap.data ?? _respaldo;
              return MarkerLayer(
                markers: [
                  for (final n in negocios)
                    Marker(
                      point: n.punto,
                      width: 46,
                      height: 46,
                      child: GestureDetector(
                        onTap: () => _mostrarFicha(context, n),
                        child: Container(
                          decoration: BoxDecoration(
                            color: n.esNosotros
                                ? const Color(0xFFB33A1A)
                                : const Color(0xFF3F5185),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              Icon(n.icono, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SimpleAttributionWidget(
            source: Text('© OpenStreetMap'),
          ),
        ],
      ),
    );
  }
}
