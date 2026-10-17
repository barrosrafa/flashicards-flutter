import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/errors/edge_error_bus.dart';
import 'supabase_client_provider.dart';

/// Unified client for invoking the 12 Supabase Edge Functions in Flashi.
///
/// Mirrors `src/lib/services/edge-error-bus.ts` and Edge Function callers in `app-flashi`:
/// - Automatically attaches Bearer JWT authorization.
/// - Parses `X-RateLimit-Remaining`, `Retry-After`, and `request_id`.
/// - Emits structured errors to `EdgeErrorBus` when a call fails or hits HTTP 429.
class EdgeFunctionClient {
  EdgeFunctionClient._({
    SupabaseClientProvider? supabaseProvider,
    EdgeErrorBus? errorBus,
  })  : _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance,
        _errorBus = errorBus ?? EdgeErrorBus.instance;

  static final EdgeFunctionClient instance = EdgeFunctionClient._();

  final SupabaseClientProvider _supabaseProvider;
  final EdgeErrorBus _errorBus;

  /// Invokes a Supabase Edge Function [functionName] with JSON [body].
  Future<Map<String, dynamic>> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final SupabaseClient? client = _supabaseProvider.client;
    if (client == null) {
      throw const OfflinePersistenceException(
        'Edge Function unavailable in offline/demo mode.',
      );
    }

    try {
      final FunctionResponse response = await client.functions.invoke(
        functionName,
        body: body,
        headers: headers,
      );

      final int status = response.status;
      final dynamic data = response.data;
      final Map<String, dynamic> decoded = data is Map<String, dynamic>
          ? data
          : (data is String && data.isNotEmpty
              ? (jsonDecode(data) as Map<String, dynamic>)
              : <String, dynamic>{});

      if (status == 429) {
        final int retrySec =
            (decoded['retry_after_seconds'] as num?)?.toInt() ?? 30;
        final RateLimitException rateError = RateLimitException(
          decoded['error']?.toString() ??
              'Limite de requisicoes atingido em $functionName.',
          retryAfterSeconds: retrySec,
          endpoint: functionName,
          requestId: decoded['request_id']?.toString(),
        );
        _errorBus.reportException(rateError, endpoint: functionName);
        throw rateError;
      }

      if (status >= 400) {
        final EdgeFunctionException edgeError = EdgeFunctionException(
          decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              'Falha na funcao $functionName (HTTP $status).',
          code: decoded['code']?.toString(),
          statusCode: status,
          requestId: decoded['request_id']?.toString(),
          endpoint: functionName,
        );
        _errorBus.reportException(edgeError, endpoint: functionName);
        throw edgeError;
      }

      return decoded;
    } on FunctionException catch (fe) {
      final int status = fe.status;
      if (status == 429) {
        final RateLimitException rateError = RateLimitException(
          fe.reasonPhrase ?? 'Rate limit exceeded on $functionName',
          retryAfterSeconds: 30,
          endpoint: functionName,
        );
        _errorBus.reportException(rateError, endpoint: functionName);
        throw rateError;
      }
      final EdgeFunctionException edgeError = EdgeFunctionException(
        fe.details?.toString() ??
            fe.reasonPhrase ??
            'Erro ao executar $functionName.',
        statusCode: status,
        endpoint: functionName,
      );
      _errorBus.reportException(edgeError, endpoint: functionName);
      throw edgeError;
    }
  }
}
