/// Onboarding learning preferences, starter deck drafts, and activation state models.
///
/// Mirrors `src/lib/learning-Onboarding.ts` and `src/lib/activation-machine.ts` from `app-flashi`.
enum LearningGoal {
  vestibular('vestibular'),
  idiomas('idiomas'),
  concursos('concursos'),
  carreira('carreira');

  const LearningGoal(this.value);
  final String value;

  static LearningGoal fromString(String? raw) {
    return LearningGoal.values.firstWhere(
      (LearningGoal g) => g.value == raw,
      orElse: () => LearningGoal.vestibular,
    );
  }
}

class LearningPreferences {
  const LearningPreferences({
    required this.goal,
    required this.dailyMinutes,
  });

  final LearningGoal goal;
  final int dailyMinutes;

  factory LearningPreferences.fromJson(Map<String, dynamic> json) {
    final int rawMinutes = (json['dailyMinutes'] as num?)?.toInt() ?? 15;
    final int validMinutes =
        (rawMinutes == 5 || rawMinutes == 15 || rawMinutes == 30)
            ? rawMinutes
            : 15;
    return LearningPreferences(
      goal: LearningGoal.fromString(json['goal']?.toString()),
      dailyMinutes: validMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'goal': goal.value,
      'dailyMinutes': dailyMinutes,
    };
  }
}

class StarterCardDraft {
  const StarterCardDraft({
    required this.front,
    required this.back,
  });

  final String front;
  final String back;
}

class LearningDraft {
  const LearningDraft({
    required this.title,
    required this.description,
    required this.cards,
  });

  final String title;
  final String description;
  final List<StarterCardDraft> cards;
}

/// Curated starter deck drafts by goal (matches `src/lib/learning-Onboarding.ts`).
const Map<LearningGoal, LearningDraft> starterDraftByGoal =
    <LearningGoal, LearningDraft>{
  LearningGoal.vestibular: LearningDraft(
    title: 'Vestibular Essencial',
    description: 'Conceitos base para revisao rapida diaria.',
    cards: <StarterCardDraft>[
      StarterCardDraft(
        front: 'Qual organela celular produz a maior parte do ATP?',
        back: 'Mitocondria.',
      ),
      StarterCardDraft(
        front: 'Formula da velocidade media na cinematica?',
        back: 'vm = delta s / delta t.',
      ),
      StarterCardDraft(
        front: 'O que caracteriza uma funcao afim?',
        back: 'Expressao na forma f(x) = ax + b, com a diferente de 0.',
      ),
      StarterCardDraft(
        front: 'Em que ano ocorreu a Proclamacao da Republica no Brasil?',
        back: '1889.',
      ),
      StarterCardDraft(
        front: 'Qual figura de linguagem ha em "choveu rios de lagrimas"?',
        back: 'Hiperbole.',
      ),
    ],
  ),
  LearningGoal.idiomas: LearningDraft(
    title: 'Ingles do Dia a Dia',
    description: 'Vocabulario e estruturas frequentes em conversas reais.',
    cards: <StarterCardDraft>[
      StarterCardDraft(
        front: 'Como dizer "depende do contexto" em ingles?',
        back: 'It depends on the context.',
      ),
      StarterCardDraft(
        front: 'Significado do phrasal verb "figure out"?',
        back: 'Entender, descobrir ou resolver algo.',
      ),
      StarterCardDraft(
        front: 'Qual a diferenca entre "actually" e "currently"?',
        back: '"Actually" = na verdade. "Currently" = atualmente.',
      ),
      StarterCardDraft(
        front: 'Complete: "I have lived here ___ 2022."',
        back: 'since',
      ),
      StarterCardDraft(
        front: 'Como perguntar educadamente por repeticao em ingles?',
        back: 'Could you repeat that, please?',
      ),
    ],
  ),
  LearningGoal.concursos: LearningDraft(
    title: 'Concursos Base',
    description: 'Pontos recorrentes de direito, portugues e logica.',
    cards: <StarterCardDraft>[
      StarterCardDraft(
        front: 'Quais sao os principios expressos no art. 37 da CF (LIMPE)?',
        back: 'Legalidade, Impessoalidade, Moralidade, Publicidade e Eficiencia.',
      ),
      StarterCardDraft(
        front: 'Quando ocorre crase antes de palavra feminina?',
        back: 'Quando ha fusao da preposicao "a" com o artigo definido "a".',
      ),
      StarterCardDraft(
        front: 'Negacao logica de "Se P, entao Q"?',
        back: 'P e nao Q.',
      ),
      StarterCardDraft(
        front: 'Qual ato administrativo nao admite revogacao?',
        back: 'Ato vinculado.',
      ),
      StarterCardDraft(
        front: 'O que significa vacatio legis?',
        back: 'Periodo entre a publicacao de uma lei e sua entrada em vigor.',
      ),
    ],
  ),
  LearningGoal.carreira: LearningDraft(
    title: 'Carreira e Produtividade',
    description: 'Fundamentos praticos para comunicacao, produto e execucao.',
    cards: <StarterCardDraft>[
      StarterCardDraft(
        front: 'O que significa a sigla SMART para metas?',
        back: 'Specific, Measurable, Achievable, Relevant, Time-bound.',
      ),
      StarterCardDraft(
        front: 'Qual o objetivo de uma retrospectiva agil?',
        back: 'Inspecionar o processo do time e definir melhorias acionaveis.',
      ),
      StarterCardDraft(
        front: 'O que e lead time em fluxo de entrega?',
        back: 'Tempo total entre o pedido e a entrega em producao.',
      ),
      StarterCardDraft(
        front: 'Estrutura basica do metodo STAR para entrevistas?',
        back: 'Situation, Task, Action, Result.',
      ),
      StarterCardDraft(
        front: 'Qual a diferenca entre output e outcome?',
        back: 'Output e o que foi entregue; outcome e o impacto gerado.',
      ),
    ],
  ),
};

int dailyMinutesToNewCardsLimit(int dailyMinutes) {
  if (dailyMinutes == 5) {
    return 10;
  }
  if (dailyMinutes == 30) {
    return 30;
  }
  return 20;
}

int dailyMinutesToReviewsLimit(int dailyMinutes) {
  if (dailyMinutes == 5) {
    return 60;
  }
  if (dailyMinutes == 30) {
    return 240;
  }
  return 140;
}

/// User onboarding state returned by `OnboardingRepository`.
class OnboardingState {
  const OnboardingState({
    required this.onboardingCompleted,
    required this.deckCount,
    this.starterDeckId,
  });

  final bool onboardingCompleted;
  final int deckCount;
  final String? starterDeckId;

  bool get needsOnboarding => !onboardingCompleted && deckCount == 0;
}

/// Result of completing onboarding and creating the starter deck.
class ActivationResult {
  const ActivationResult({
    required this.deckId,
    required this.createdStarterDeck,
  });

  final String deckId;
  final bool createdStarterDeck;
}
