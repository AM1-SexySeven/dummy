/// Comparación de texto pensada para buscar en español.
///
/// Quien busca escribiendo rara vez pone las tildes, y quien busca
/// hablando no las pone nunca: el reconocimiento de voz devuelve
/// «artesanía» o «artesania» según el día. Si el filtro comparara el
/// texto tal cual, media búsqueda no encontraría nada.
class Texto {
  const Texto._();

  static const Map<String, String> _equivalencias = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  /// Pasa el texto a minúsculas y le quita las tildes y la diéresis.
  ///
  /// La eñe se convierte en ene a propósito: así «cuñape» encuentra
  /// «cuñapé» aunque el teclado no tenga la tecla.
  static String normalizar(String valor) {
    final buffer = StringBuffer();
    for (final caracter in valor.toLowerCase().split('')) {
      buffer.write(_equivalencias[caracter] ?? caracter);
    }
    return buffer.toString().trim();
  }

  /// true si [texto] contiene [busqueda], sin distinguir mayúsculas,
  /// minúsculas ni tildes. Una búsqueda vacía encuentra todo.
  static bool contiene(String texto, String busqueda) {
    final aguja = normalizar(busqueda);
    if (aguja.isEmpty) return true;
    return normalizar(texto).contains(aguja);
  }

  /// true si alguno de los [campos] contiene la búsqueda.
  ///
  /// Sirve para buscar un negocio por su nombre o por su rubro con la
  /// misma palabra, que es lo que pide la consigna: decir «artesanía»
  /// y que aparezcan los negocios de ese rubro aunque ninguno se
  /// llame así.
  static bool contieneEnAlguno(List<String> campos, String busqueda) {
    final aguja = normalizar(busqueda);
    if (aguja.isEmpty) return true;
    return campos.any((c) => normalizar(c).contains(aguja));
  }
}
