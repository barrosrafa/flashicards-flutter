/// Configuração central de variáveis de ambiente para o cliente mobile Flashi.
///
/// Nenhuma chave de serviço (`service_role` / `sb_secret_...` / `OPENAI_API_KEY`)
/// pode residir neste arquivo ou no bundle da aplicação.
class EnvConfig {
  const EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_URL',
    defaultValue: String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ykyobzoxoiljyueasdwc.supabase.co',
    ),
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  static const String siteUrl = String.fromEnvironment(
    'NEXT_PUBLIC_SITE_URL',
    defaultValue: 'https://flashi.app',
  );

  static const String authRedirectUri = 'io.flashi.app://auth-callback';

  static const String sentryDsn = String.fromEnvironment(
    'NEXT_PUBLIC_SENTRY_DSN',
    defaultValue: '',
  );

  static const String sentryEnvironment = String.fromEnvironment(
    'NEXT_PUBLIC_SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );

  static const String posthogProjectToken = String.fromEnvironment(
    'NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN',
    defaultValue: '',
  );

  static const String posthogHost = String.fromEnvironment(
    'NEXT_PUBLIC_POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  static const bool posthogEnabled = bool.fromEnvironment(
    'NEXT_PUBLIC_POSTHOG_ENABLED',
    defaultValue: false,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
