import '../../core/utils/crypto_utils.dart';
import '../../domain/models/socratic_session.dart';
import '../local/app_database.dart';
import '../remote/edge_function_client.dart';
import '../remote/supabase_client_provider.dart';

/// Repository for Socratic AI Tutor remediation sessions (`socratic-tutor` Edge Function).
///
/// Mirrors `src/lib/services/socratic-service.ts` from `app-flashi`.
class SocraticRepository {
  SocraticRepository({
    FlashiLocalDatabase? database,
    EdgeFunctionClient? edgeClient,
    SupabaseClientProvider? supabaseProvider,
  })  : _database = database ?? FlashiLocalDatabase.instance,
        _edgeClient = edgeClient ?? EdgeFunctionClient.instance,
        _supabaseProvider = supabaseProvider ?? SupabaseClientProvider.instance;

  final FlashiLocalDatabase _database;
  final EdgeFunctionClient _edgeClient;
  final SupabaseClientProvider _supabaseProvider;

  /// Starts or continues a Socratic remediation dialogue for a lapsed card.
  Future<SocraticSession> sendTurn({
    required String userId,
    required String cardId,
    required String cardFront,
    required String cardBack,
    String? sessionId,
    String? userMessage,
  }) async {
    if (_supabaseProvider.isAvailable) {
      try {
        final Map<String, dynamic> res = await _edgeClient.invoke(
          'socratic-tutor',
          body: <String, dynamic>{
            'cardId': cardId,
            if (sessionId != null) 'sessionId': sessionId,
            if (userMessage != null) 'message': userMessage,
          },
        );
        final SocraticSession remoteSession = SocraticSession.fromJson(res);
        await _database.upsertRow(
          'socratic_remediation_sessions',
          remoteSession.toJson(),
        );
        return remoteSession;
      } catch (_) {}
    }

    // Local Socratic tutor fallback so users can interact offline or in demo mode
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final String effectiveSessionId = sessionId ?? CryptoUtils.generateUuidV4();
    final Map<String, dynamic>? existingRow = await _database.getRow(
      'socratic_remediation_sessions',
      effectiveSessionId,
    );

    final List<SocraticMessage> messages = existingRow != null
        ? SocraticSession.fromJson(existingRow).messages.toList()
        : <SocraticMessage>[];

    if (messages.isEmpty) {
      messages.add(
        SocraticMessage(
          role: 'ai',
          content:
              'Percebi que este cartao exigiu reforco ("$cardFront"). Sem olhar a resposta final ainda: qual pista ou principio fundamental voce lembra sobre esse topico?',
          timestamp: nowIso,
        ),
      );
    } else if (userMessage != null && userMessage.trim().isNotEmpty) {
      messages.add(
        SocraticMessage(
          role: 'user',
          content: userMessage.trim(),
          timestamp: nowIso,
        ),
      );
      final bool isSecondTurn =
          messages.where((SocraticMessage m) => !m.isAi).length >= 2;
      messages.add(
        SocraticMessage(
          role: 'ai',
          content: isSecondTurn
              ? 'Excelente raciocinio! Voce conectou a ideia-chave a resposta ("$cardBack"). Sessao socratica concluida com sucesso.'
              : 'Bom caminho! Agora conecte essa pista ao efeito principal esperado para chegar em "$cardBack". Como voce formularia com suas palavras?',
          timestamp: nowIso,
        ),
      );
    }

    final SocraticStatus nextStatus =
        messages.where((SocraticMessage m) => !m.isAi).length >= 2
            ? SocraticStatus.resolved
            : SocraticStatus.inProgress;

    final SocraticSession session = SocraticSession(
      id: effectiveSessionId,
      userId: userId,
      cardId: cardId,
      status: nextStatus,
      messages: messages,
      createdAt: existingRow?['created_at']?.toString() ?? nowIso,
      updatedAt: nowIso,
    );

    await _database.upsertRow(
      'socratic_remediation_sessions',
      session.toJson(),
    );
    return session;
  }
}
