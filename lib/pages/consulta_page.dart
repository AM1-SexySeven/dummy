import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

/// Pantalla para enviar una consulta al negocio.
class ConsultaPage extends StatefulWidget {
  const ConsultaPage({super.key});

  @override
  State<ConsultaPage> createState() => _ConsultaPageState();
}

class _ConsultaPageState extends State<ConsultaPage> {
  final _ctrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final mensaje = _ctrl.text.trim();
    if (mensaje.isEmpty) {
      setState(() => _error = 'Escriba su consulta primero');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await SupabaseService.enviarConsulta(mensaje: mensaje);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta enviada a Churrasquería El Fogón')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'No se pudo enviar la consulta: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Consultar a Churrasquería El Fogón',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Escríbanos su duda sobre platos, horarios o atención. '
                'Le responderemos por la app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Su consulta',
                  hintText: 'Ej: ¿Tienen parrillada para 8 personas el sábado?',
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
                icon: const Icon(Icons.send_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar consulta', style: TextStyle(fontSize: 16)),
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
