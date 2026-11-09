import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'registro_page.dart';

/// Pantalla de inicio de sesión.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text;

    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _error = 'Ingrese un correo válido');
      return;
    }
    if (clave.isEmpty) {
      setState(() => _error = 'Ingrese su clave');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await SupabaseService.iniciarSesion(correo: correo, clave: clave);
      if (!mounted) return;
      Navigator.pop(context, true);
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
    if (texto.contains('Invalid login credentials')) {
      return 'Correo o clave incorrectos';
    }
    if (texto.contains('Email not confirmed')) {
      return 'Confirme su correo antes de entrar';
    }
    if (texto.contains('no está configurado')) {
      return 'Supabase no está configurado. Edita lib/config.dart';
    }
    if (texto.contains('SocketException') || texto.contains('Failed to fetch')) {
      return 'Sin conexión. Revisa tu internet';
    }
    return 'No se pudo iniciar sesión. Intente de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Icon(Icons.login_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Bienvenido de nuevo',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Ingrese su correo y su clave',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Correo
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

              // Clave
              TextField(
                controller: _claveCtrl,
                obscureText: true,
                onSubmitted: (_) => _entrar(),
                decoration: const InputDecoration(
                  labelText: 'Clave',
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

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _cargando ? null : _entrar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _cargando
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistroPage(),
                          ),
                        );
                      },
                child: const Text('No tengo cuenta  →  Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}