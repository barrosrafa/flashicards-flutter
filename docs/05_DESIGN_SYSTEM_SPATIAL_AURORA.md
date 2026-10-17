# 05. Design System "Spatial Aurora (Cyber-Glass)" e Ergonomia Mobile

Este documento detalha os tokens visuais de 3 camadas, a escala tipográfica, a anatomia de componentes e os padrões de interação multi-toque do **Flashi Mobile**.

---

## 1. Benchmark Competitivo e Posicionamento Visual

| Concorrente | Pontos Fortes | Limitações Superadas pelo Flashi Mobile |
| :--- | :--- | :--- |
| **AnkiMobile / AnkiDroid** | Poder algorítmico, Cloze e `.apkg` offline. | Interface utilitária datada e curva de aprendizado íngreme. O Flashi combina FSRS-6 + `.apkg` com estética **Spatial Aurora** e Onboarding de 30s. |
| **Quizlet** | Animações fluidas e facilidade inicial. | Sem repetição espaçada científica real (FSRS-6) no fluxo gratuito e limitações offline. |
| **RemNote** | Oclusão de imagem e conexão entre notas. | Denso em telas pequenas de smartphone. O Flashi isola o editor de oclusão em um canvas multi-toque dedicado e foca a revisão na zona do polegar. |
| **Mochi / Gizmo** | Minimalismo e gamificação (streaks/XP). | Falta de ecossistema completo (MCP, Tutor Socrático IA, Modo Prova e otimizador de 21 pesos). |

---

## 2. Arquitetura de Tokens de Cor ([`FlashiColorTokens`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/theme/flashi_color_tokens.dart))

O tema padrão é **Dark OLED ("Deep Obsidian Void")**, reduzindo a fadiga ocular em sessões noturnas de estudo e economizando bateria em telas AMOLED/Super Retina XDR, com suporte completo ao modo claro (**"Alabaster Daylight"**):

| Token Semântico | Dark OLED (Padrão) | Light ("Alabaster Daylight") | Uso no Sistema |
| :--- | :--- | :--- | :--- |
| `bgCanvas` | `#05070E` | `#F8FAFC` | Fundo principal da tela ([`AuroraScaffold`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/widgets/aurora_scaffold.dart)) |
| `bgElevated` | `#0B1021` | `#FFFFFF` | Modais, bottom sheets e superfícies destacadas |
| `surfaceGlassPrimary` | `#BF0F172A` (75% alpha) | `#D9FFFFFF` (85% alpha) | Cartões Bento ([`GlassBentoCard`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/widgets/glass_bento_card.dart)) e barra de navegação |
| `borderSpecular` | `#1FFFFFFF` (12% branco) | `#140F172A` (8% slate) | Borda especular de `1px` nos cartões de vidro |
| `accentCyan` | `#00F2FE` (Electric Cyan) | `#0284C7` | Ação primária, foco neural e indicadores ativos |
| `accentViolet` | `#8B5CF6` (Neural Violet) | `#7C3AED` | Gradientes Aurora, IA Socrática e MCP |
| `ratingAgain` | `#FF3B5C` (Crimson) | `#E11D48` | Botão FSRS "De novo" + alertas de erro |
| `ratingHard` | `#FFB800` (Amber) | `#D97706` | Botão FSRS "Difícil" + Modo Prova + Rate Limit |
| `ratingGood` | `#00E676` (Mint) | `#059669` | Botão FSRS "Bom" + status sincronizado |
| `ratingEasy` | `#00E5FF` (Cyan) | `#0284C7` | Botão FSRS "Fácil" + freezes de ofensiva |

---

## 3. Escala Tipográfica ([`FlashiTypography`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/core/theme/flashi_typography.dart))

1. **Display & Títulos (`Space Grotesk`):** Geométrica e tecnológica, usada em contadores do Dashboard, cabeçalhos de seção e títulos de baralhos (`displayLarge` 34px, `displayMedium` 28px, `headlineMedium` 24px).
2. **Corpo de Cartão & Leitura Longa (`Plus Jakarta Sans`):** Altíssima legibilidade em telas móveis, com altura de linha generosa (`1.5x`) para perguntas e respostas extensas.
3. **Telemetria, Intervalos FSRS & USN (`JetBrains Mono`):** Com `FontFeature.tabularFigures()` ativado para que contadores (`<10m`, `5d`, `USN 1042`, `req_id`) nunca causem jitter horizontal ao atualizar.

---

## 4. Componentes Espaciais e Interações Nativas

### 4.1 Flip 3D com Perspectiva Física ([`StudySessionScreen`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/study/study_session_screen.dart))
Utiliza `AnimationController` de `360ms` combinado a uma matriz de transformação 3D com perspectiva real na coluna $Z$:
```dart
final Matrix4 transform = Matrix4.identity()
  ..setEntry(3, 2, 0.001)
  ..rotateY(angle);
```
Quando $\text{angle} \ge \pi / 2$, o conteúdo interno recebe uma contra-rotação de $\pi$ radianos para que o texto do verso nunca fique espelhado.

### 4.2 Editor de Oclusão de Imagem Normalizado `0..100%` ([`ImageOcclusionEditorScreen`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/ui/features/occlusion/image_occlusion_editor_screen.dart))
Converte qualquer gesto de arraste (`onPanStart`, `onPanUpdate`, `onPanEnd`) sobre o `LayoutBuilder` da imagem em coordenadas percentuais canônicas (`[0.0, 100.0]`) via [`OcclusionMask.fromNormalizedDrag`](file:///Users/rafaelaparecido/projects/flashcards-flutter/lib/domain/models/occlusion_mask.dart#L31-L50), garantindo que máscaras criadas no celular alinhem perfeitamente no tablet ou na web.
