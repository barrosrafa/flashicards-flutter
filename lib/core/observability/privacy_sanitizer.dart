/// Sanitizador de telemetria equivalente a `lib/observability/privacy.ts`.
///
/// Garante que nenhum token, cookie, header de autorização, e-mail, prompt,
/// conteúdo de cartão/nota ou chave de idempotência seja enviado a Sentry/PostHog.
class PrivacySanitizer {
  const PrivacySanitizer._();

  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(token|secret|password|authorization|cookie|email|front|back|fields|prompt|content|idempotency|jwt|bearer|apikey|api_key)',
    caseSensitive: false,
  );

  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      if (_sensitiveKeyPattern.hasMatch(entry.key)) {
        continue;
      }
      result[entry.key] = _sanitizeValue(entry.value);
    }
    return result;
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is String) {
      if (value.length > 240) {
        return '${value.substring(0, 240)}...';
      }
      return value;
    }
    if (value is Map) {
      return sanitizeMap(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    if (value is Iterable) {
      return value.take(20).map(_sanitizeValue).toList(growable: false);
    }
    return value.toString();
  }
}
