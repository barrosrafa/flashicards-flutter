/// Validadores compartilhados equivalentes a `lib/supabase/guards.ts`,
/// `lib/services/mcp-client.ts` e `lib/services/import-deck-service.ts`.
class Validators {
  const Validators._();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static final RegExp _isoDateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool isUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  static bool isIsoDate(String? value) {
    if (value == null || !_isoDateRegex.hasMatch(value)) return false;
    final parsed = DateTime.tryParse('${value}T12:00:00Z');
    return parsed != null && parsed.toIso8601String().substring(0, 10) == value;
  }

  static bool isPrivateIpv4(String hostname) {
    final parts = hostname.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
    final a = octets[0]!;
    final b = octets[1]!;
    return a == 0 ||
        a == 10 ||
        a == 127 ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 192 && b == 0) ||
        (a == 192 && b == 2) ||
        (a == 198 && (b == 18 || b == 19 || b == 51)) ||
        (a == 203 && b == 0) ||
        a >= 224;
  }

  static bool isPrivateIpv6(String hostname) {
    final value = hostname.toLowerCase();
    return value == '::' ||
        value == '::1' ||
        value.startsWith('fc') ||
        value.startsWith('fd') ||
        value.startsWith('fe80:') ||
        value.startsWith('::ffff:');
  }

  /// Valida um endpoint MCP ou URL de importação contra ataques SSRF.
  static Uri validatePublicHttpsEndpoint(
    String rawEndpoint, {
    String requiredError = 'MCP_ENDPOINT_REQUIRED',
    String invalidError = 'MCP_ENDPOINT_INVALID',
    String httpsError = 'MCP_ENDPOINT_HTTPS_REQUIRED',
    String credentialsError = 'MCP_ENDPOINT_CREDENTIALS_IN_URL',
    String privateHostError = 'MCP_ENDPOINT_PRIVATE_HOST',
  }) {
    final trimmed = rawEndpoint.trim();
    if (trimmed.isEmpty || trimmed.length > 2048) {
      throw Exception(requiredError);
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw Exception(invalidError);
    }
    if (uri.scheme != 'https') {
      throw Exception(httpsError);
    }
    if (uri.userInfo.isNotEmpty) {
      throw Exception(credentialsError);
    }
    final host = uri.host
        .toLowerCase()
        .replaceAll(RegExp(r'^\[|\]$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    if (host.isEmpty ||
        host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal') ||
        host.endsWith('.home.arpa') ||
        isPrivateIpv4(host) ||
        isPrivateIpv6(host)) {
      throw Exception(privateHostError);
    }
    return uri;
  }

  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String? validateRequired(
    String? value, {
    String fieldName = 'Campo',
    int minLength = 1,
    int maxLength = 5000,
  }) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return '$fieldName é obrigatório.';
    }
    if (trimmed.length < minLength) {
      return '$fieldName deve ter pelo menos $minLength caracteres.';
    }
    if (trimmed.length > maxLength) {
      return '$fieldName excede o limite de $maxLength caracteres.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Informe um endereço de e-mail válido.';
    }
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 8}) {
    final String raw = value ?? '';
    if (raw.isEmpty) {
      return 'Informe sua senha.';
    }
    if (raw.length < minLength) {
      return 'A senha deve ter pelo menos $minLength caracteres.';
    }
    return null;
  }

  static String? validateIntRange(
    String? value, {
    required String fieldName,
    required int min,
    required int max,
  }) {
    final String trimmed = (value ?? '').trim();
    final int? parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return '$fieldName deve ser um número inteiro.';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName deve estar entre $min e $max.';
    }
    return null;
  }
}
