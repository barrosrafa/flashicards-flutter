# Flashi Mobile — Índice Geral da Documentação Técnica (`docs/`)

Bem-vindo à documentação de engenharia do **Flashi Mobile (Flutter)** — a conversão mobile nativa (`Android .apk/.aab` & `iOS .ipa`) do repositório [`barrosrafa/app-flashi`](https://github.com/barrosrafa/app-flashi) integrada ao backend Supabase [`barrosrafa/Flashi`](https://github.com/barrosrafa/Flashi).

---

## Sumário dos Módulos de Documentação

1. [**01. Arquitetura Limpa (Clean Architecture + MVVM) e Modelo de Domínio**](./01_ARCHITECTURE_AND_DOMAIN_MODEL.md)
   - Diagrama de camadas (`UI`, `Core/DI`, `Domain`, `Data`)
   - Catálogo completo dos **15 Modelos Imutáveis** (`Deck`, `Note`, `Flashcard`, `DueCard`, `ReviewResult`, `CardTemplate`, `OcclusionMask`, `DeckExam`, `Gamification`, `SocraticSession`, `IngestionJob`, `AnkiTransfer`, `AnalyticsSummary`, `LearningPreferences`, `UserProfile`)
   - Especificação dos **3 Serviços Puros de Domínio**: `TemplateRenderer` (sintaxe Anki/Cloze), `NoteCardFieldsDeriver` e `ActivationStateMachine`.

2. [**02. Motor Offline-First, Sincronização USN (`BigInt`) nas 28 Tabelas e Outbox Queue**](./02_OFFLINE_SYNC_USN_AND_OUTBOX.md)
   - Mapeamento das **28 tabelas sincronizadas** (`SyncTables.allTables`) e chaves primárias compostas
   - Algoritmo monotônico de resolução de conflitos por cursor `BigInt` USN (`applyDeltaBatch`)
   - Coalescência de idempotência (`idempotency_key`) e adiamento automático de `sync_session_xp_confirmed` até que todos os `review_logs` da sessão sejam confirmados (`OutboxQueue`).

3. [**03. Contratos de Backend: Supabase, 12 Edge Functions, 14+ RPCs e 3 Buckets Privados**](./03_BACKEND_CONTRACTS_SUPABASE_AND_EDGE.md)
   - Tabela de referência das **12 Edge Functions** (`review-card`, `sync-pull`, `ingest-document`, `import-deck`, `anki-import`, `anki-export`, `semantic-search`, `socratic-tutor`, `optimize-fsrs-params`, `mcp`, `export-user-data`, `delete-account`)
   - Tratamento global de erros e limite de taxa (`HTTP 429 Retry-After`) via `EdgeErrorBus`, `RateLimitBanner` e `EdgeErrorBanner`
   - Catálogo das **RPCs PostgreSQL transacionais** e regras dos **3 Buckets Privados** (`card-media`, `anki-transfers`, `import-media`).

4. [**04. Motor Matemático FSRS-6 (21 Pesos), Modo Prova e Tutor Socrático IA**](./04_FSRS6_ALGORITHM_AND_STUDY_ENGINE.md)
   - Modelo matemático DSR (*Difficulty, Stability, Retrievability*) e vetor padrão de **21 pesos FSRS-6**
   - Cálculo dinâmico do multiplicador de compressão de intervalo do **Modo Prova** ($1.0 \le m \le 2.5$)
   - Fluxo de remediação guiada pelo **Tutor Socrático IA** quando o usuário avalia um cartão como `De novo` (`Again`).

5. [**05. Design System "Spatial Aurora (Cyber-Glass)" e Ergonomia Mobile**](./05_DESIGN_SYSTEM_SPATIAL_AURORA.md)
   - Análise competitiva (Anki, Quizlet, RemNote, Mochi, Gizmo)
   - Tokens semânticos de 3 camadas para **Dark OLED (`#05070E`)** e **Light ("Alabaster Daylight" `#F8FAFC`)**
   - Escala tipográfica (`Space Grotesk`, `Plus Jakarta Sans`, `JetBrains Mono` tabular)
   - Flip 3D com matriz de perspectiva física (`Matrix4`) e Editor de Oclusão Multi-Toque (`0..100%`).

6. [**06. Guia Completo de Geração de `.ipa` (iOS) e `.apk` / `.aab` (Android)**](./06_BUILD_RELEASE_IPA_AND_APK_GUIDE.md)
   - Anatomia do pacote `.ipa` gerado em [`build/ios/ipa/Flashi.ipa`](../build/ios/ipa/Flashi.ipa)
   - Uso do script automatizado [`scripts/build_ipa.sh`](../scripts/build_ipa.sh)
   - Assinatura Apple Distribution (App Store / TestFlight), Ad-Hoc e Sideload sem conta paga (`--no-codesign`)
   - Geração de `.apk` (`--split-per-abi`) e `.aab` com R8/ProGuard e CI/CD no GitHub Actions.
