# 07. Relatório de Remediação QA, Gaps Funcionais e Changelog Técnico

**Data:** 16 de Outubro de 2026  
**Revisão Base Auditada:** `84843ca417f2615fb9bd743642faac236abc11ca`  
**Escopo da Intervenção:** Resolução de 100% dos bloqueios de compilação (`QA-01` a `QA-04`), unificação de modelos e serializadores (`QA-02`, `QA-05`), integridade de sincronização, FSRS-6 e autenticação (`QA-06` a `QA-39`), implementação dos 16 Gaps Funcionais de UX e homologação da matriz `E2E-01` a `E2E-32`.

---

## 1. Matriz de Resolução dos 39 Apontamentos de QA (`QA-01` a `QA-39`)

| ID | Severidade | Descrição do Problema | Arquivos Remediados | Solução Implementada |
|---|---|---|---|---|
| **QA-01** | Bloqueante | Símbolos ausentes chamados no runtime e core (`runGuarded`, `AppLocalizations`, etc.) | [observability_service.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/observability/observability_service.dart), [app_localizations.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/l10n/app_localizations.dart), [validators.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/utils/validators.dart), [haptics_helper.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/utils/haptics_helper.dart), [crypto_utils.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/utils/crypto_utils.dart), [app_exceptions.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/errors/app_exceptions.dart), [edge_error_bus.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/errors/edge_error_bus.dart), [date_range_bounds.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/utils/date_range_bounds.dart) | Implementado `runGuarded` assíncrono com captura de erro; adicionadas chaves l10n completas; implementados validadores de formulário, hápticos, gerador UUIDv4, taxonomia de exceções e bus de erros. |
| **QA-02** | Bloqueante | Modelos de domínio com campos faltando e nomes divergentes entre banco e UI | `lib/domain/models/`: [deck.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/deck.dart), [note.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/note.dart), [due_card.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/due_card.dart), [flashcard.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/flashcard.dart), [review_result.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/review_result.dart), [card_template.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/card_template.dart), [occlusion_mask.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/occlusion_mask.dart), [deck_exam.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/deck_exam.dart) | Unificação completa dos modelos com getters/aliases retrocompatíveis (`title`/`name`, `front`/`frontTemplate`, `reps`, `lapses`, `stability`, `difficulty`, `position`, `copyWith`, `clampPercentage`, `fromNormalizedDrag`). |
| **QA-03** | Bloqueante | Dependência do pacote `fsrs` e constantes de buckets privadas ausentes | [pubspec.yaml](file:///Users/rafaelaparecido/projects/flashcards-flutter/pubspec.yaml), [storage_buckets.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/constants/storage_buckets.dart) | Adicionado `fsrs: ^2.0.1` ao `pubspec.yaml` e declaradas as constantes dos 3 buckets privados (`card-media`, `anki-transfers`, `import-media`). |
| **QA-04** | Bloqueante | Diretórios e arquivos nativos do Android e iOS incompletos no repositório | `android/**`, `ios/**`, [.github/workflows/build-mobile-releases.yml](file:///Users/rafaelaparecido/projects/flashcards-flutter/.github/workflows/build-mobile-releases.yml) | Criados `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradle-wrapper`, `styles.xml`, `project.pbxproj`, `AppFrameworkInfo.plist`, Storyboards e CI/CD unificado com `--dart-define`. |
| **QA-05** | Alta | Divergência de nomes em chamadas a repositórios e serializadores | `lib/data/repositories/**` | Padronizados os nomes dos parâmetros e métodos em todos os repositórios para coincidir com os modelos unificados de domínio. |
| **QA-06 a QA-11** | Alta | Discrepância entre prévia de intervalos na UI e gravação no banco, vazamento de demo cards para usuários logados e concorrência na submissão | [study_repository.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/study_repository.dart), [study_session_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/study/study_session_screen.dart), [fsrs_scheduler_adapter.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/services/fsrs_scheduler_adapter.dart) | Criado o `FsrsSchedulerAdapter` centralizado; restrito `demoCards` a `userId == 'demo-user-id'`; adicionada trava de concorrência `_isSubmitting`; implementada tela de finalização de sessão. |
| **QA-12 a QA-15** | Alta | Inicialização degradada do SQLite sem flag pública e ausência de limpeza por usuário | [app_database.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/local/app_database.dart) | Adicionada flag pública `isPersistenceDegraded`, registro de log via `ObservabilityService` e método `clearUserDataForUser(userId)`. |
| **QA-16 a QA-19** | Alta | Cadastro sem retorno tipado de confirmação de e-mail, rotas desprotegidas contra anônimos e falta de suporte a deep link PKCE | [auth_repository.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/auth_repository.dart), [auth_callback_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/auth/auth_callback_screen.dart), [app_router.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/router/app_router.dart), [register_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/auth/register_screen.dart), [onboarding_repository.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/onboarding_repository.dart) | Retorno `SignUpOutcome`, escuta de auth state, rota `/auth-callback` com `exchangeCodeForSession`, guardas de redirecionamento no `GoRouter` e idempotência no onboarding. |
| **QA-20 a QA-29** | Alta/Média | Falta de fallback offline na Outbox para oclusão e exames, e falta de deck picker no agendador de provas | [occlusion_repository.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/occlusion_repository.dart), [exam_repository.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/exam_repository.dart), [exam_scheduler_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/exams/exam_scheduler_screen.dart) | Injetada `OutboxQueue` no repositório de oclusão e exame; implementado dropdown de seleção de baralho alvo no agendamento de provas. |
| **QA-30 a QA-32** | Alta/Média | Retentativas da Outbox inflando em falhas puras de rede e falta de método para reprocessar falhas | [outbox_queue.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/local/outbox_queue.dart), [sync_engine.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/local/sync_engine.dart) | `_isNetworkOfflineError` não incrementa contadores em falhas de conectividade; adicionado método `retryFailedOperations()`; suporte a rate-limit com `retryAfterSeconds` e paginação até 50 páginas. |
| **QA-33 a QA-39** | Média | Falta de edição de cartões em detalhes do baralho, acessibilidade incompleta e botões sem semântica | [deck_detail_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/decks/deck_detail_screen.dart), [study_session_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/study/study_session_screen.dart) | Adicionado modal `_showEditCardModal` e botão de edição de notas e cartões existentes; adicionados nós de acessibilidade com `Semantics(button: true, label: ...)`. |

---

## 2. Fechamento dos 16 Gaps Funcionais de Produto

1. **Gap 1 — Motor FSRS-6 Real:** Substituição de heurísticas mockadas pela biblioteca `fsrs` encapsulada em `FsrsSchedulerAdapter`.
2. **Gap 2 — Prévia e Submissão Unificadas:** Intervalos exibidos nos 4 botões (`<10m`, `2d`, etc.) coincidem exatamente com o cálculo gravado.
3. **Gap 3 — Isolamento Demo vs. Real:** `demoCards` restrito estritamente a `userId == 'demo-user-id'`.
4. **Gap 4 — Edição de Notas e Cartões Existentes:** Modal `_showEditCardModal` implementado em [deck_detail_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/decks/deck_detail_screen.dart).
5. **Gap 5 — Seletor de Baralhos no Agendador de Provas:** Dropdown dinâmico com a lista de baralhos do usuário em [exam_scheduler_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/exams/exam_scheduler_screen.dart).
6. **Gap 6 — Enfileiramento Offline de Oclusão de Imagem:** Máscaras e cartões gerados offline são persistidos localmente e enfileirados na Outbox.
7. **Gap 7 — Enfileiramento Offline de Conclusão de Exame:** Conclusão de exames funciona sem conexão e sincroniza no retorno da rede.
8. **Gap 8 — Idempotência no Onboarding:** Ativação de novos usuários não duplica decks iniciais nem falha offline.
9. **Gap 9 — Tratamento de Deep Link de Autenticação:** `AuthCallbackScreen` intercepta links `io.flashi.app://auth-callback` e faz a troca de código por sessão.
10. **Gap 10 — Guardas de Rota contra Acesso Anônimo:** Usuários sem login são redirecionados automaticamente para `/login` ao tentar acessar `/dashboard`, `/decks`, `/study`.
11. **Gap 11 — Resiliência de Erros de Rede na Outbox:** Quedas de Wi-Fi/4G não jogam operações da Outbox para quarentena (dead-letter queue).
12. **Gap 12 — Botão de Reprocessamento de Mutações com Falha:** Método `retryFailedOperations()` exposto na Outbox e no painel de sincronização.
13. **Gap 13 — Paginação Robusta no Sync Engine:** Suporte a até 50 páginas de deltas por ciclo em bases grandes.
14. **Gap 14 — Proteção de Concorrência na Revisão:** Flag `_isSubmitting` impede cliques múltiplos duplicando avaliações.
15. **Gap 15 — Acessibilidade Completa (A11y):** Rótulos semânticos (`Semantics`) para leitores de tela em todos os botões de revisão e virada de cartão.
16. **Gap 16 — Scaffolds Nativos Android/iOS Completos:** Criação de toda a estrutura nativa para compilação de binários `.apk`, `.aab` e `.ipa`.

---

## 3. Matriz de Homologação E2E (`E2E-01` a `E2E-32`)

- **E2E-01 a E2E-05 (Autenticação e Onboarding):** Cadastro com feedback de e-mail, login por senha, troca PKCE, onboarding idempotente e guardas de rota validados.
- **E2E-06 a E2E-10 (Sessão de Estudo FSRS-6):** Fila de revisão, cálculo DSR, multiplicador de prova, feedback háptico e proteção contra duplo clique validados.
- **E2E-11 a E2E-15 (CRUD de Decks, Notas e Cartões):** Criação, edição in-place, deleção e renderização Cloze validados.
- **E2E-16 a E2E-20 (Oclusão e Provas):** Desenho de máscaras normalizadas, geração 1:1 de cartões, agendamento com seletor de baralho e compressão temporal validados.
- **E2E-21 a E2E-25 (Offline-First e Sincronização):** Gravação em SQLite, fila Outbox, coalescência de idempotência, adiamento de XP e resolução monotônica USN validados.
- **E2E-26 a E2E-30 (Importações e Mídia):** Transferência Anki `.apkg`, importação estruturada (CSV/TSV/TXT) e referências a buckets privados validados.
- **E2E-31 a E2E-32 (Acessibilidade e CI/CD):** Navegação com leitores de tela e pipeline automatizado no GitHub Actions validados.

---

## 4. Inventário dos Arquivos Criados e Modificados

### Arquivos Criados
- [lib/domain/services/fsrs_scheduler_adapter.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/services/fsrs_scheduler_adapter.dart)
- [lib/ui/features/auth/auth_callback_screen.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/auth/auth_callback_screen.dart)
- [test/domain/fsrs_scheduler_adapter_test.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/test/domain/fsrs_scheduler_adapter_test.dart)
- [test/domain/deck_exam_test.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/test/domain/deck_exam_test.dart)
- [test/data/study_repository_fsrs_test.dart](file:///Users/rafaelaparecido/projects/flashcards-flutter/test/data/study_repository_fsrs_test.dart)
- `android/build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradle-wrapper`
- `android/app/src/main/res/values/styles.xml`, `launch_background.xml`
- `ios/Runner.xcodeproj/project.pbxproj`, `ios/Flutter/AppFrameworkInfo.plist`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `Main.storyboard`
- `docs/07_REMEDIACAO_QA_E_CHANGELOG.md`

### Arquivos Modificados (33 arquivos)
- `pubspec.yaml`, `lib/main.dart`
- `lib/core/**`: `observability_service.dart`, `app_localizations.dart`, `validators.dart`, `haptics_helper.dart`, `crypto_utils.dart`, `storage_buckets.dart`, `date_range_bounds.dart`, `app_exceptions.dart`, `edge_error_bus.dart`, `app_router.dart`
- `lib/domain/models/**`: `deck.dart`, `note.dart`, `due_card.dart`, `flashcard.dart`, `review_result.dart`, `card_template.dart`, `occlusion_mask.dart`, `deck_exam.dart`
- `lib/data/local/**`: `app_database.dart`, `outbox_queue.dart`, `sync_engine.dart`
- `lib/data/repositories/**`: `study_repository.dart`, `auth_repository.dart`, `onboarding_repository.dart`, `occlusion_repository.dart`, `exam_repository.dart`
- `lib/ui/features/**`: `study_session_screen.dart`, `deck_detail_screen.dart`, `exam_scheduler_screen.dart`, `register_screen.dart`
- `.github/workflows/build-mobile-releases.yml`
