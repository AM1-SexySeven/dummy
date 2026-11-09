import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

/// Pantalla de registro de cuenta nueva.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _aviso;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text;

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingrese su nombre');
      return;
    }
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _error = 'Ingrese un correo válido');
      return;
    }
    if (clave.length < 6) {
      setState(() => _error = 'La clave debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });

    try {
      await SupabaseService.registrar(
        nombre: nombre,
        correo: correo,
        clave: clave,
      );
      if (!mounted) return;

      // Si Supabase pide confirmar correo, no hay sesión todavía.
      if (SupabaseService.haySesion) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _cargando = false;
          _aviso = 'Cuenta creada. Revise su correo para confirmarla';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = _mensajeError(e);
      });
    }
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('already registered') ||
        texto.contains('already been registered')) {
      return 'Ese correo ya está registrado';
    }
    if (texto.contains('weak_password')) {
      return 'La clave es muy débil (mínimo 6 caracteres)';
    }
    if (texto.contains('no está configurado')) {
      return 'Supabase no está configurado. Edita lib/config.dart';
    }
    if (texto.contains('SocketException') || texto.contains('Failed to fetch')) {
      return 'Sin conexión. Revisa tu internet';
    }
    return 'No se pudo crear la cuenta. Intente de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Icon(Icons.person_add_rounded,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Regístrate en ConectaCruz',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Cree su cuenta para consultar y reservar',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Su nombre',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _claveCtrl,
                obscureText: true,
                onSubmitted: (_) => _registrar(),
                decoration: const InputDecoration(
                  labelText: 'Clave (mínimo 6 caracteres)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_aviso != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _aviso!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Volver a iniciar sesión'),
                ),
              ],

              if (_aviso == null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _registrar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrarme', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _cargando ? null : () => Navigator.pop(context),
                  child: const Text('Ya tengo cuenta  →  Iniciar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}