import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_service.dart';

/// Pantalla para hacer una reserva en el negocio.
class ReservaPage extends StatefulWidget {
  const ReservaPage({super.key});

  /// true cuando la combinación fecha+hora es futura.
  static bool fechaHoraValida(DateTime fecha, TimeOfDay hora) {
    final elegido =
        DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    return elegido.isAfter(DateTime.now());
  }

  @override
  State<ReservaPage> createState() => _ReservaPageState();
}

class _ReservaPageState extends State<ReservaPage> {
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  int _personas = 2;
  TimeOfDay _hora = const TimeOfDay(hour: 20, minute: 0);
  final _ctrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (sel != null && mounted) setState(() => _fecha = sel);
  }

  Future<void> _elegirHora() async {
    final sel = await showTimePicker(context: context, initialTime: _hora);
    if (sel != null && mounted) setState(() => _hora = sel);
  }

  String get _fechaTexto {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${_fecha.day} ${meses[_fecha.month - 1]} ${_fecha.year}';
  }

  Future<void> _enviar() async {
    // No se pueden reservar fechas u horas que ya pasaron.
    if (!ReservaPage.fechaHoraValida(_fecha, _hora)) {
      setState(() {
        _enviando = false;
        _error = 'La fecha y hora elegidas ya pasaron. Elija una fecha futura.';
      });
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await SupabaseService.enviarReserva(
        fecha: _fecha,
        personas: _personas,
        detalle:
            '$_fechaTexto a las ${_hora.format(context)}. ${_ctrl.text.trim()}',
      );
      if (!mounted) return;
      final nombreUsuario = SupabaseService.usuario?.userMetadata?['nombre'] ??
          SupabaseService.usuario?.email ??
          'Cliente';
      final hora = _hora.format(context);
      final mensaje = StringBuffer()
        ..write('Hola 👋, soy $nombreUsuario.\n')
        ..write('Confirmo mi reserva en Churrasquería El Fogón:\n')
        ..write('$_fechaTexto · $hora · $_personas persona(s).');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 48),
          title: const Text('¡Reserva confirmada!'),
          content: Text(
            'El $_fechaTexto a las $hora para $_personas persona(s).\n\n'
            '¿Avisas por WhatsApp para que te confirmen la mesa?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Más tarde'),
            ),
            FilledButton.icon(
              onPressed: () async {
                // El número vigente del negocio se lee de Supabase
                final info = await SupabaseService.cargarNegocio();
                final url = Uri.parse(
                  'https://wa.me/${info.numeroWa}?text=${Uri.encodeComponent(mensaje.toString())}',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Avisar por WhatsApp'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva enviada para el $_fechaTexto a las ${_hora.format(context)}',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'No se pudo enviar la reserva: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Reservar en Churrasquería El Fogón',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Fecha
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('Fecha'),
                  subtitle: Text(_fechaTexto),
                  trailing: const Icon(Icons.edit_calendar_rounded),
                  onTap: _elegirFecha,
                ),
              ),
              const SizedBox(height: 8),

              // Hora
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Hora'),
                  subtitle: Text(_hora.format(context)),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: _elegirHora,
                ),
              ),
              const SizedBox(height: 8),

              // Personas
              Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: const Text('Personas'),
                  subtitle: Text('$_personas'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        onPressed: _personas > 1
                            ? () => setState(() => _personas--)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        onPressed: _personas < 30
                            ? () => setState(() => _personas++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _ctrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Detalle (opcional)',
                  hintText: 'Ej: Mesa cerca de la parrilla, cumpleaños...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
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
                onPressed: _enviando ? null : _enviar,
                icon: const Icon(Icons.check_circle_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar reserva',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _enviando ? null : () => Navigator.pop(context),
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

