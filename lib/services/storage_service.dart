import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de intentar subir una foto.
///
/// Se distingue «el usuario canceló» de «falló»: cancelar no es un
/// error y la pantalla no debe mostrar ningún aviso rojo por eso.
enum ResultadoFoto { subida, cancelada, sinPermiso, sinConexion, rechazada, error }

class SubidaFoto {
  const SubidaFoto(this.resultado, {this.url, this.mensaje});

  final ResultadoFoto resultado;

  /// Dirección pública de la foto, cuando la subida salió bien.
  final String? url;

  /// Qué mostrarle a la persona cuando no salió bien.
  final String? mensaje;

  bool get ok => resultado == ResultadoFoto.subida;
  bool get cancelada => resultado == ResultadoFoto.cancelada;
}

/// Fotos de los platos, guardadas en Supabase Storage.
///
/// El dueño del negocio elige una foto de la galería o la saca con la
/// cámara, la aplicación la sube al depósito `negocios` y guarda su
/// dirección pública en la columna `imagen_url` del plato.
///
/// Los permisos de cámara y galería los pide el propio `image_picker`
/// en el momento, no hace falta pedirlos antes.
class StorageService {
  StorageService._();

  static const String bucket = 'negocios';
  static const String carpeta = 'platos';

  /// Ancho máximo al que se reduce la foto antes de subirla.
  ///
  /// Una foto de celular pesa varios megabytes y en pantalla se ve a
  /// 240 píxeles. Reducirla ahorra datos móviles al dueño que la sube
  /// y a cada cliente que después la mira.
  static const double anchoMaximo = 1280;
  static const int calidad = 80;

  static final ImagePicker _selector = ImagePicker();

  static SupabaseClient get _db => Supabase.instance.client;

  /// Abre la galería o la cámara, sube la foto y devuelve su dirección.
  ///
  /// [productoId] identifica el plato: el archivo se guarda como
  /// `platos/<id>/<marca de tiempo>.jpg`. El nombre lleva la hora para
  /// que cada cambio de foto genere un archivo nuevo y no haya que
  /// pelear con el caché de imágenes del teléfono.
  static Future<SubidaFoto> subirFotoPlato({
    required String productoId,
    required ImageSource origen,
  }) async {
    try {
      final foto = await _selector.pickImage(
        source: origen,
        maxWidth: anchoMaximo,
        imageQuality: calidad,
      );

      // Cancelar no es un error.
      if (foto == null) return const SubidaFoto(ResultadoFoto.cancelada);

      final bytes = await foto.readAsBytes();
      final ruta = '$carpeta/$productoId/'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _db.storage.from(bucket).uploadBinary(
            ruta,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = _db.storage.from(bucket).getPublicUrl(ruta);
      return SubidaFoto(ResultadoFoto.subida, url: url);
    } on StorageException catch (e) {
      // El servidor contestó, pero rechazó la operación.
      final texto = e.message.toLowerCase();
      if (texto.contains('row-level security') ||
          texto.contains('unauthorized') ||
          texto.contains('policy')) {
        return const SubidaFoto(
          ResultadoFoto.rechazada,
          mensaje: 'Esta cuenta no tiene permiso para cambiar la foto. '
              'Solo el dueño del negocio puede hacerlo.',
        );
      }
      if (texto.contains('not found') || texto.contains('bucket')) {
        return const SubidaFoto(
          ResultadoFoto.error,
          mensaje: 'Falta crear el depósito de fotos en Supabase '
              '(script 11_storage_fotos.sql).',
        );
      }
      return SubidaFoto(ResultadoFoto.error, mensaje: e.message);
    } on TimeoutException {
      return const SubidaFoto(
        ResultadoFoto.sinConexion,
        mensaje: 'La subida está tardando demasiado. Intentá de nuevo.',
      );
    } catch (e) {
      final texto = e.toString();
      if (texto.contains('SocketException') ||
          texto.contains('Failed host lookup') ||
          texto.contains('ClientException')) {
        return const SubidaFoto(
          ResultadoFoto.sinConexion,
          mensaje: 'Sin conexión a internet. La foto no se subió.',
        );
      }
      if (texto.contains('photo_access_denied') ||
          texto.contains('camera_access_denied')) {
        return const SubidaFoto(
          ResultadoFoto.sinPermiso,
          mensaje: 'Falta el permiso de cámara o de galería. '
              'Se puede activar desde los ajustes del teléfono.',
        );
      }
      return const SubidaFoto(
        ResultadoFoto.error,
        mensaje: 'No se pudo subir la foto. Intentá de nuevo.',
      );
    }
  }
}
