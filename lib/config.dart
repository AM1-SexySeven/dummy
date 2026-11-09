/// Credenciales del proyecto de Supabase.
///
/// Proyecto: `conecta-cruz` (organización MarcoKiataque-org)
/// Región: South America (São Paulo)
///
/// Cómo obtenerlas (si se recrea el proyecto):
///  1. https://supabase.com → proyecto → ⚙ Project Settings → API Keys
///  2. Copiar la "Project URL" y la "Publishable key"
class SupabaseConfig {
  /// URL del proyecto (termina en .supabase.co)
  static const String url = 'https://lhzmwtndbledovzdovqd.supabase.co';

  /// Clave pública "publishable" (segura para la app, no es un secreto)
  static const String anonKey =
      'sb_publishable_ZD7Yq7WnAiOL4A5xF09BXQ_z2P88KJO';

  /// true mientras no se hayan pegado credenciales reales.
  /// La app funciona en "modo demo" con datos de ejemplo.
  static bool get sinConfigurar =>
      url.contains('TU-PROYECTO') || anonKey.contains('TU-ANON-KEY');
}
