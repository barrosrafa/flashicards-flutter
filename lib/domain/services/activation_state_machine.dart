/// Activation state machine for first-session onboarding and starter deck flow.
///
/// Mirrors `src/lib/activation-machine.ts` from `app-flashi`.
enum ActivationStage {
  uninitialized,
  selectingGoal,
  provisioningStarterDeck,
  firstStudySession,
  completed,
}

class ActivationMachineState {
  const ActivationMachineState({
    required this.stage,
    this.starterDeckId,
    this.cardsReviewedInFirstSession = 0,
    this.targetFirstSessionCards = 5,
    this.errorMessage,
  });

  final ActivationStage stage;
  final String? starterDeckId;
  final int cardsReviewedInFirstSession;
  final int targetFirstSessionCards;
  final String? errorMessage;

  bool get isActivated => stage == ActivationStage.completed;

  double get progressFraction {
    if (stage == ActivationStage.completed) {
      return 1.0;
    }
    if (targetFirstSessionCards <= 0) {
      return 0.0;
    }
    return (cardsReviewedInFirstSession / targetFirstSessionCards)
        .clamp(0.0, 1.0);
  }

  ActivationMachineState copyWith({
    ActivationStage? stage,
    String? starterDeckId,
    int? cardsReviewedInFirstSession,
    int? targetFirstSessionCards,
    String? errorMessage,
  }) {
    return ActivationMachineState(
      stage: stage ?? this.stage,
      starterDeckId: starterDeckId ?? this.starterDeckId,
      cardsReviewedInFirstSession:
          cardsReviewedInFirstSession ?? this.cardsReviewedInFirstSession,
      targetFirstSessionCards:
          targetFirstSessionCards ?? this.targetFirstSessionCards,
      errorMessage: errorMessage,
    );
  }
}

class ActivationStateMachine {
  const ActivationStateMachine._();

  static ActivationMachineState resolveInitialState({
    required bool onboardingCompleted,
    required int deckCount,
    String? starterDeckId,
  }) {
    if (onboardingCompleted || deckCount > 0) {
      return ActivationMachineState(
        stage: ActivationStage.completed,
        starterDeckId: starterDeckId,
      );
    }
    return const ActivationMachineState(
      stage: ActivationStage.selectingGoal,
    );
  }

  static ActivationMachineState onStarterDeckProvisioned(
    ActivationMachineState current,
    String deckId,
  ) {
    return current.copyWith(
      stage: ActivationStage.firstStudySession,
      starterDeckId: deckId,
      cardsReviewedInFirstSession: 0,
    );
  }

  static ActivationMachineState onFirstSessionCardReviewed(
    ActivationMachineState current,
  ) {
    final int nextCount = current.cardsReviewedInFirstSession + 1;
    if (nextCount >= current.targetFirstSessionCards) {
      return current.copyWith(
        stage: ActivationStage.completed,
        cardsReviewedInFirstSession: nextCount,
      );
    }
    return current.copyWith(
      stage: ActivationStage.firstStudySession,
      cardsReviewedInFirstSession: nextCount,
    );
  }
}
