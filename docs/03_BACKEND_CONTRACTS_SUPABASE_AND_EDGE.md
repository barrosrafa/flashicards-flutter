# 03. Contratos de Backend: Supabase, 12 Edge Functions, 14+ RPCs e 3 Buckets Privados

Este documento especifica todos os contratos de rede entre o **Flashi Mobile (Flutter)** e o backend **Supabase (`barrosrafa/Flashi`)**, incluindo autenticação JWT/PKCE, tratamento de Rate Limit (`HTTP 429`), funções PostgreSQL transacionais e políticas de armazenamento privado.

---

## 1. As 12 Supabase Edge Functions (`EdgeFunctionClient`)

Todas as chamadas passam pelo cliente centralizado [`EdgeFunctionClient`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/remote/edge_function_client.dart), que anexa automaticamente o Bearer Token JWT da sessão ativa e publica falhas ou alertas de limite de taxa no [`EdgeErrorBus`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/errors/edge_error_bus.dart).

| # | Edge Function | Repositório Consumidor | Payload de Entrada (JSON) | Resposta / Comportamento |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `review-card` | [`StudyRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/study_repository.dart) | `{ cardId, rating (1..4), durationMs, idempotencyKey }` | Persiste `review_logs` idempotente, atualiza `card_learning_state` e retorna `{ state, dueDate, intervalDays, stability, difficulty, reps, lapses }`. |
| 2 | `sync-pull` | [`SyncEngine`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/local/sync_engine.dart) | `{ since_usn: String, tables: List<String> }` | Retorna `{ changes: Map<tableName, List<row>>, max_usn: String, has_more: bool }` para sincronização incremental monotônica. |
| 3 | `ingest-document` | [`IngestionRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/ingestion_repository.dart) | `{ deckId, sourceType, content?, sourceUrl?, maxCards }` | Extrai conceitos via LLM e cria notas/cartões FSRS-6 registrando o job em `ai_ingestion_jobs`. |
| 4 | `import-deck` | [`ImportRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/import_repository.dart) | `{ deckId, format ('csv'\|'tsv'\|'txt'\|'json'\|'markdown'\|'xml'), content }` | Processa lotes de cartões estruturados e retorna `{ jobId, deckId, importedCount, failedCount }`. |
| 5 | `anki-import` | [`AnkiTransferRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/anki_transfer_repository.dart) | `{ storagePath, fileName, deckId?, includeScheduling }` | Descompacta pacote `.apkg`/`.colpkg` do bucket `anki-transfers`, importa notas, modelos Cloze, mídias e revisões. |
| 6 | `anki-export` | [`AnkiTransferRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/anki_transfer_repository.dart) | `{ deckId?, includeScheduling, includeMedia }` | Gera arquivo `.apkg` ou `.colpkg` compatível com Anki Desktop/AnkiDroid e retorna URL assinada (`downloadUrl`). |
| 7 | `semantic-search` | [`SearchRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/search_repository.dart) | `{ query, deckId?, limit }` | Gera embedding `text-embedding-3-small` (1536 dim) e executa busca híbrida (`hybrid_search_cards` RRF). |
| 8 | `socratic-tutor` | [`SocraticRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/socratic_repository.dart) | `{ cardId, sessionId?, message? }` | Conduz diálogo socrático guiado por IA sem entregar a resposta imediatamente; atualiza `socratic_remediation_sessions`. |
| 9 | `optimize-fsrs-params` | [`OptimizerRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/optimizer_repository.dart) | `{ userId }` | Analisa `>= 400` registros em `review_logs` e recalibra o vetor personalizado de 21 pesos FSRS-6 (`w[0..20]`). |
| 10 | `mcp` | [`McpExternalClient`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/remote/mcp_external_client.dart) | `{ method: 'tools/list' \| 'tools/call', params }` | Expõe ferramentas do Model Context Protocol com auditoria em `mcp_tool_audit`. |
| 11 | `export-user-data` | [`ProfileRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/profile_repository.dart) | `{ format: 'json' }` | Exporta portabilidade completa de dados do usuário (LGPD/GDPR). |
| 12 | `delete-account` | [`ProfileRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/profile_repository.dart) | `{ confirm: true }` | Remove permanentemente a conta, objetos de Storage e registros associados. |

---

## 2. Tratamento de Erros e Rate Limit (`HTTP 429`)

1. Quando qualquer Edge Function retorna `status == 429`:
   - [`EdgeFunctionClient`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/remote/edge_function_client.dart) extrai `retry_after_seconds` e `request_id` do payload JSON.
   - Dispara uma [`RateLimitException`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/errors/app_exceptions.dart) no [`EdgeErrorBus`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/errors/edge_error_bus.dart).
   - O widget global [`RateLimitBanner`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/widgets/rate_limit_banner.dart) exibe automaticamente o alerta âmbar com o contador de segundos no topo do [`AuroraScaffold`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/widgets/aurora_scaffold.dart).
2. Quando ocorre erro `HTTP >= 400` (exceto 429):
   - O [`EdgeErrorBanner`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/widgets/edge_error_banner.dart) exibe a mensagem amigável acompanhada do `req_id` em fonte monoespaçada (`JetBrains Mono`) para rastreamento imediato nos logs do Supabase.

---

## 3. Catálogo de RPCs PostgreSQL (`client.rpc(...)`)

| RPC PostgreSQL | Parâmetros Principais | Finalidade Transacional |
| :--- | :--- | :--- |
| `get_due_cards` | `p_user_id`, `p_deck_id`, `p_limit` | Retorna cartões vencidos ou novos respeitando limites diários e hierarquia de decks. |
| `submit_review` | `p_card_id`, `p_rating`, `p_duration_ms`, `p_idempotency_key`, `p_reviewed_at` | Grava revisão idempotente diretamente via RPC durante o flush da `OutboxQueue`. |
| `mcp_create_note` | `p_deck_id`, `p_model_kind`, `p_field_values`, `p_cards`, `p_template_id` | Cria transacionalmente a `note`, os `cards` derivados e inicializa `card_learning_state` (`state='new'`) para que apareçam imediatamente em `get_due_cards`. |
| `update_note_and_cards_v2` | `p_note_id`, `p_field_values`, `p_cards` | Atualiza os campos da nota e sincroniza os cartões filhos preservando o histórico FSRS-6. |
| `stage_image_occlusion_asset` | `p_storage_path`, `p_file_name`, `p_mime_type`, `p_size_bytes` | Registra o ativo de imagem no banco antes de gerar as máscaras de oclusão. |
| `create_image_occlusion_note` | `p_deck_id`, `p_storage_path`, `p_masks`, `p_title`, `p_extra` | Cria a nota `image_occlusion`, persiste as caixas em `note_image_occlusion_boxes` e gera 1 cartão por máscara. |
| `sync_session_xp_confirmed` | `p_user_id`, `p_session_id`, `p_review_keys`, `p_activity_date` | Valida as revisões confirmadas da sessão, credita XP, recalcula nível e atualiza a ofensiva diária (`streak`). |
| `clone_public_deck` | `p_source_deck_id` | Clona um baralho público da comunidade (com suas notas e cartões) para o espaço privado do usuário. |
| `hybrid_search_cards` | `query_text`, `query_embedding`, `match_count` | Combina similaridade cosseno (`pgvector`) + ranking léxico (`tsvector`) via Reciprocal Rank Fusion (RRF). |
| `get_deck_true_retention` | `p_deck_id`, `p_days` | Calcula a curva histórica de retenção verdadeira sobre cartões maduros (`stability >= 21`). |

---

## 4. Buckets Privados do Supabase Storage ([`StorageBuckets`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/constants/storage_buckets.dart))

| Bucket | Visibilidade | Limite por Arquivo | Quota Total / Usuário | Padrão de Caminho (`storage_path`) |
| :--- | :--- | :--- | :--- | :--- |
| `card-media` | Privado (RLS + Signed URL 3600s) | `10 MB` | `50 MB` | `{userId}/{cardId}/{uuid}.{ext}` ou `{userId}/occlusion/{uuid}.{ext}` |
| `anki-transfers` | Privado (RLS) | `250 MB` | Temporário por Job | `{userId}/{jobId}/{fileName}.apkg` |
| `import-media` | Privado (RLS) | `50 MB` | Temporário por Job | `{userId}/{jobId}/{fileName}` |
