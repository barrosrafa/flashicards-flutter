/// Hierarquia de exceções tipadas compatível com `lib/services/http/errors.ts`,
/// `lib/services/occlusion-service.ts` e `lib/services/media-service.ts`.
class AppException implements Exception {
  const AppException(
    this.message, {
    required this.code,
    this.status = 0,
    this.requestId,
    this.cause,
  });

  final String message;
  final String code;
  final int status;
  final String? requestId;
  final Object? cause;

  @override
  String toString() => message;
}

class EdgeError extends AppException {
  const EdgeError(
    this.functionName,
    int status,
    String message, [
    this.payload,
    String code = 'EDGE_ERROR',
  ]) : super(
          message,
          code: code,
          status: status,
        );

  final String functionName;
  final Object? payload;
}

class AuthRequiredError extends EdgeError {
  const AuthRequiredError([String functionName = 'auth'])
      : super(
          functionName,
          401,
          'Sua sessão expirou ou você precisa entrar na sua conta.',
          null,
          'AUTH_REQUIRED',
        );
}

class EdgeTimeoutError extends EdgeError {
  const EdgeTimeoutError(String functionName, this.timeoutMs)
      : super(
          functionName,
          408,
          'A operação "$functionName" excedeu o tempo limite de ${(timeoutMs ~/ 1000)}s.',
          null,
          'EDGE_TIMEOUT',
        );

  final int timeoutMs;
}

class RateLimitError extends EdgeError {
  const RateLimitError(
    String functionName,
    this.retryAfterSec, [
    Object? payload,
  ]) : super(
          functionName,
          429,
          'Muitas solicitações para "$functionName". Aguarde ${retryAfterSec}s antes de tentar novamente.',
          payload,
          'RATE_LIMITED',
        );

  final int retryAfterSec;
}

class UnavailableError extends EdgeError {
  const UnavailableError(
    String functionName, [
    String message = 'Serviço temporariamente indisponível.',
    Object? payload,
  ]) : super(
          functionName,
          503,
          message,
          payload,
          'SERVICE_UNAVAILABLE',
        );
}

class OcclusionRpcError extends AppException {
  const OcclusionRpcError(
    super.message, {
    required super.code,
    required super.status,
    required String super.requestId,
    this.details,
    this.hint,
    super.cause,
  });

  final String? details;
  final String? hint;

  String toActionableMessage() {
    const messages = <String, String>{
      'OCCLUSION_NOTE_OR_DECK_NOT_OWNED':
          'A nota não existe ou não pertence a este deck. Confirme a nota e o deck selecionados.',
      'OCCLUSION_ASSET_NOT_FOUND_OR_NOT_OWNED':
          'O upload não está mais disponível para esta conta. Envie a imagem novamente.',
      'OCCLUSION_MASKS_MUST_BE_PERCENTAGES':
          'Revise as caixas: posição e tamanho devem estar entre 0 e 100% e caber na imagem.',
      'OCCLUSION_MASKS_REQUIRED':
          'Desenhe pelo menos uma caixa antes de criar os cartões.',
      'AUTH_REQUIRED':
          'Sua sessão expirou. Entre novamente e tente criar os cartões.',
    };
    final base = messages[code] ?? message;
    return '$base (código $code, status $status, requestId $requestId)';
  }
}

class MediaServiceError extends AppException {
  const MediaServiceError(
    super.message, {
    required super.code,
    super.status = 400,
    super.requestId,
    super.cause,
  });

  String toActionableMessage() {
    final statusSuffix = status > 0 ? ', status $status' : '';
    final reqSuffix = requestId != null ? ', requestId $requestId' : '';
    return '$message (código $code$statusSuffix$reqSuffix)';
  }
}
