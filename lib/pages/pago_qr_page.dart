import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/pasarela_simulada.dart';
import '../services/qr_service.dart';
import '../utils/emv_qr.dart';

/// Pantalla de pago por QR.
///
/// Pide el código al banco, lo muestra con su cuenta regresiva y espera
/// el aviso del pago. Cubre las cinco situaciones que puede encontrar
/// un cliente de verdad: mientras carga, con el QR en pantalla, cuando
/// el código vence, cuando falla la red y cuando el pago entra.
class PagoQrPage extends StatefulWidget {
  const PagoQrPage({
    super.key,
    required this.pedidoId,
    required this.monto,
  });

  final int pedidoId;
  final double monto;

  @override
  State<PagoQrPage> createState() => _PagoQrPageState();
}

enum _Vista { cargando, conQr, error, vencido, pagado }

class _PagoQrPageState extends State<PagoQrPage> {
  late Future<void> _primeraCarga;

  _Vista _vista = _Vista.cargando;
  Cobro? _cobro;
  String _mensajeError = '';
  CobroError? _tipoError;

  Timer? _reloj;
  Timer? _consultaRespaldo;
  StreamSubscription<EstadoCobro>? _escucha;
  int _segundos = 0;

  @override
  void initState() {
    super.initState();
    // El Future se crea una sola vez acá, nunca dentro de build().
    _primeraCarga = _pedirQr();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _consultaRespaldo?.cancel();
    _escucha?.cancel();
    super.dispose();
  }

  String _bs(double v) => 'Bs ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _pedirQr() async {
    setState(() => _vista = _Vista.cargando);

    final res = await QrService.generarQr(
      pedidoId: widget.pedidoId,
      monto: widget.monto,
    );

    if (!mounted) return;

    if (res.hayError) {
      setState(() {
        _vista = res.error == CobroError.vencido ? _Vista.vencido : _Vista.error;
        _tipoError = res.error;
        _mensajeError = res.mensaje ?? 'No se pudo generar el código.';
      });
      return;
    }

    final cobro = res.cobro!;

    // El QR llegó, pero antes de mostrarlo se comprueba su suma de
    // verificación. Un QR corrupto lo rechazaría la banca móvil.
    if (!EmvQr.esValido(cobro.qrPayload)) {
      setState(() {
        _vista = _Vista.error;
        _tipoError = CobroError.respuestaInvalida;
        _mensajeError =
            'El código que devolvió el banco está dañado. Intentá de nuevo.';
      });
      return;
    }

    setState(() {
      _cobro = cobro;
      _segundos = cobro.segundosRestantes;
      _vista = cobro.pagado ? _Vista.pagado : _Vista.conQr;
    });

    if (cobro.pagado) {
      _avisarPagado();
      return;
    }

    _arrancarReloj();
    _arrancarEscucha(cobro.id);
    _arrancarConsultaRespaldo(cobro.id);
  }

  /// Cuenta regresiva hasta que el QR deja de servir.
  void _arrancarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_segundos <= 0) {
        t.cancel();
        _escucha?.cancel();
        _consultaRespaldo?.cancel();
        setState(() => _vista = _Vista.vencido);
        return;
      }
      setState(() => _segundos--);
    });
  }

  /// Aviso en vivo: el banco informa el pago y la pantalla cambia sola.
  void _arrancarEscucha(String cobroId) {
    final p = QrService.pasarela;
    if (p is! PasarelaSimulada) return;
    _escucha?.cancel();
    _escucha = p.escucharEstado(cobroId).listen((estado) {
      if (!mounted) return;
      if (estado == EstadoCobro.pagado) _marcarPagado();
      if (estado == EstadoCobro.vencido) {
        setState(() => _vista = _Vista.vencido);
      }
    });
  }

  /// Consulta de respaldo, por si el aviso en vivo no llega.
  /// Nunca hay que depender de un solo canal para saber si cobramos.
  void _arrancarConsultaRespaldo(String cobroId) {
    _consultaRespaldo?.cancel();
    _consultaRespaldo = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        if (!mounted || _vista != _Vista.conQr) return;
        final res = await QrService.consultarEstado(cobroId);
        if (!mounted) return;
        if (res.error == CobroError.vencido) {
          setState(() => _vista = _Vista.vencido);
        } else if (res.cobro?.pagado == true) {
          _marcarPagado();
        }
      },
    );
  }

  void _marcarPagado() {
    _reloj?.cancel();
    _consultaRespaldo?.cancel();
    _escucha?.cancel();
    setState(() => _vista = _Vista.pagado);
    _avisarPagado();
  }

  Future<void> _avisarPagado() async {
    // Se queda unos segundos en «¡Pago recibido!» antes de volver, para
    // que el cliente alcance a verlo y se pueda capturar la pantalla.
    await Future<void>.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.pop(context, true);
  }

  /// Botón de prueba: solo aparece con el banco simulado.
  Future<void> _pagarDePrueba() async {
    final p = QrService.pasarela;
    if (p is! PasarelaSimulada || _cobro == null) return;
    final res = await p.simularPago(_cobro!.id);
    if (!mounted) return;
    if (res.error == CobroError.yaPagado) {
      // Pago duplicado: no se cobra dos veces.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este pedido ya estaba pagado.')),
      );
      _marcarPagado();
    } else if (res.hayError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.mensaje ?? 'No se pudo registrar el pago.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con QR'),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _primeraCarga,
        builder: (context, _) {
          switch (_vista) {
            case _Vista.cargando:
              return _centrado([
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Pidiéndole el código al banco…'),
              ]);

            case _Vista.error:
              return _centrado([
                Icon(Icons.cloud_off_rounded,
                    size: 72, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _tipoError == CobroError.sinConexion
                      ? 'Sin conexión a internet'
                      : 'No se pudo generar el código',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_mensajeError, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _primeraCarga = _pedirQr();
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ]);

            case _Vista.vencido:
              return _centrado([
                Icon(Icons.timer_off_rounded,
                    size: 72, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('El código QR venció',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Por seguridad, cada código sirve diez minutos. '
                    'Tu pedido sigue guardado: generá uno nuevo.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _primeraCarga = _pedirQr();
                  }),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Generar otro código'),
                ),
              ]);

            case _Vista.pagado:
              return _centrado([
                const Icon(Icons.check_circle_rounded,
                    size: 88, color: Colors.green),
                const SizedBox(height: 16),
                Text('¡Pago recibido!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_bs(widget.monto), style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('El negocio ya está preparando tu pedido.'),
              ]);

            case _Vista.conQr:
              return _vistaQr(theme);
          }
        },
      ),
    );
  }

  Widget _centrado(List<Widget> hijos) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: hijos,
        ),
      );

  Widget _vistaQr(ThemeData theme) {
    final cobro = _cobro!;
    final minutos = (_segundos ~/ 60).toString().padLeft(2, '0');
    final segs = (_segundos % 60).toString().padLeft(2, '0');
    final porVencer = _segundos <= 60;
    final esSimulado = QrService.pasarela is PasarelaSimulada;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(_bs(cobro.monto),
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Pedido N.º ${widget.pedidoId}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 20),

          // El código
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: cobro.qrPayload!,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 20),

          // Cuenta regresiva
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 20,
                  color: porVencer
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline),
              const SizedBox(width: 6),
              Text(
                'Vence en $minutos:$segs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: porVencer ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(EstadoCobro.pendiente.texto),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Abrí tu banca móvil, elegí «Pagar con QR» y escaneá este '
              'código. El pedido se confirma solo cuando el banco avisa '
              'que recibió el pago.',
              textAlign: TextAlign.center,
            ),
          ),

          if (esSimulado) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Modo de pruebas',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pagarDePrueba,
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Simular que el banco confirma el pago'),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            '${QrService.pasarela.nombre} · cuenta ${QrService.cuenta}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          if (cobro.idBanco != null)
            Text('Referencia ${cobro.idBanco}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
