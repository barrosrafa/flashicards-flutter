# 04. Motor Matemático FSRS-6 (21 Pesos), Modo Prova e Tutor Socrático IA

Este documento detalha a implementação matemática do algoritmo **FSRS-6 (Free Spaced Repetition Scheduler v6)** utilizado no [`StudyRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/study_repository.dart), o cálculo de compressão dinâmica de intervalos do **Modo Prova** ([`DeckExam`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/deck_exam.dart)) e a integração com o **Tutor Socrático por IA** ([`SocraticTutorSheet`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/socratic/socratic_tutor_sheet.dart)).

---

## 1. Vetor de 21 Pesos do FSRS-6 (`defaultFsrs6Weights`)

Definido em [`FsrsOptimizationStatus.defaultFsrs6Weights`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/analytics_summary.dart#L114-L136):

$$w = [0.2120, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.0010, 1.8722, 0.1666, 0.7960, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542]$$

### Variáveis de Estado de Memória (`DSR Model`)
Cada cartão possui em `card_learning_state`:
- **Estabilidade ($S > 0$)**: Tempo (em dias) necessário para que a probabilidade de recordação ($R$) caia de $100\%$ para $90\%$.
- **Dificuldade ($D \in [1.0, 10.0]$)**: Complexidade intrínseca do item para o estudante.
- **Recuperabilidade ($R \in (0, 1]$)**: Probabilidade estimada de lembrar o cartão após $t$ dias decorridos desde a última revisão (`elapsed_days`):

$$R(t, S) = \left(1 + \text{FACTOR} \cdot \frac{t}{S}\right)^{-w_{20}}$$

Onde $\text{FACTOR} = 0.9^{-1 / w_{20}} - 1$, garantindo que $R(S, S) = 0.90$.

---

## 2. Cálculo do Próximo Intervalo e Avaliações (`1..4`)

Ao avaliar um cartão na [`StudySessionScreen`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/study/study_session_screen.dart), o estudante escolhe uma das 4 respostas na zona do polegar:

| Botão | Código (`ReviewRating`) | Cor Semântica | Efeito no Estado FSRS-6 | Feedback Háptico ([`HapticsHelper`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/core/utils/haptics_helper.dart)) |
| :--- | :--- | :--- | :--- | :--- |
| **De novo** (`Again`) | `1` | `#FF3B5C` (Crimson) | Incrementa `lapses`, transita para `learning`/`relearning` (`< 10 min`) e aciona o **Tutor Socrático IA**. | `heavyImpact()` |
| **Difícil** (`Hard`) | `2` | `#FFB800` (Amber) | Aumenta $D$, aplica crescimento conservador em $S$ e agenda para curto prazo. | `mediumImpact()` |
| **Bom** (`Good`) | `3` | `#00E676` (Mint) | Mantém $D$ equilibrado e multiplica $S$ para atingir a retenção desejada ($r_d$, padrão $0.90$). | `lightImpact()` |
| **Fácil** (`Easy`) | `4` | `#00E5FF` (Cyan) | Reduz $D$ e aplica bônus de estabilidade em $S$ para intervalo longo. | `selectionClick()` |

---

## 3. Multiplicador de Compressão do Modo Prova (`Exam Boost`)

Implementado em [`DeckExam.computeIntervalBoostMultiplier`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/deck_exam.dart#L75-L94), quando um baralho possui uma prova ativa agendada para daqui a $d$ dias (`daysRemaining`):

1. **Fator de Urgência Temporal ($u$):**
   $$u = \begin{cases} 1.35 & \text{se } d \le 7 \\ 1.20 & \text{se } 7 < d \le 14 \\ 1.10 & \text{se } 14 < d \le 30 \\ 1.00 & \text{se } d > 30 \end{cases}$$

2. **Fator de Prioridade ($p$):**
   - `high`: $p = 1.25$
   - `medium`: $p = 1.12$
   - `low`: $p = 1.05$

3. **Fator de Retenção Alvo ($r_{\text{boost}}$):**
   $$r_{\text{boost}} = 1.0 + \max(0, r_{\text{alvo}} - 0.90) \cdot 4.0$$

4. **Multiplicador Final ($m \in [1.0, 2.5]$):**
   $$m = \text{clamp}(u \cdot p \cdot r_{\text{boost}}, 1.0, 2.5)$$
   $$I_{\text{final}} = \max\left(1, \text{round}\left(\frac{I_{\text{FSRS}}}{m}\right)\right)$$

Isso comprime os intervalos de revisão de forma inteligente nas semanas que antecedem o exame, maximizando a probabilidade de recordação no dia da prova sem destruir o histórico de estabilidade de longo prazo.

---

## 4. Fluxo de Remediação do Tutor Socrático IA

Quando o usuário pressiona **De novo (`Again`)** durante a sessão de estudo:
1. A [`StudySessionScreen`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/study/study_session_screen.dart) abre automaticamente o modal [`SocraticTutorSheet`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/socratic/socratic_tutor_sheet.dart).
2. O [`SocraticRepository`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/data/repositories/socratic_repository.dart) invoca a Edge Function `socratic-tutor` (ou executa o motor socrático local se offline).
3. Em vez de simplesmente mostrar a resposta passivamente, a IA formula uma pergunta norteadora sobre a pista/princípio fundamental do cartão (`status = in_progress`).
4. Após 2 turnos de raciocínio ativo do estudante, a sessão é marcada como `resolved` e o estudo prossegue.
