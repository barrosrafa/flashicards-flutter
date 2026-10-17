import '../../domain/models/deck.dart';
import 'card_repository.dart';
import 'deck_repository.dart';
import 'study_repository.dart';

/// Aggregated dashboard summary data for the Spatial Bento Grid home screen.
///
/// Mirrors `src/lib/services/dashboard-service.ts` from `app-flashi`.
class DashboardData {
  const DashboardData({
    required this.decks,
    required this.totalDecks,
    required this.totalCards,
    required this.dueCount,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final List<Deck> decks;
  final int totalDecks;
  final int totalCards;
  final int dueCount;
  final int newCount;
  final int learningCount;
  final int reviewCount;
}

class DashboardRepository {
  DashboardRepository({
    DeckRepository? deckRepository,
    CardRepository? cardRepository,
    StudyRepository? studyRepository,
  })  : _deckRepository = deckRepository ?? DeckRepository(),
        _cardRepository = cardRepository ?? CardRepository(),
        _studyRepository = studyRepository ?? StudyRepository();

  final DeckRepository _deckRepository;
  final CardRepository _cardRepository;
  final StudyRepository _studyRepository;

  Future<DashboardData> getDashboardData(String userId) async {
    final List<Deck> decks = await _deckRepository.listDecks(userId: userId);
    final int totalCards = await _cardRepository.countAllCards(userId: userId);
    final dueCards = await _studyRepository.getDueCards(
      userId: userId,
      limit: 200,
    );

    int newCount = 0;
    int learningCount = 0;
    int reviewCount = 0;

    for (final card in dueCards) {
      if (card.state == 'new') {
        newCount++;
      } else if (card.state == 'learning' || card.state == 'relearning') {
        learningCount++;
      } else {
        reviewCount++;
      }
    }

    return DashboardData(
      decks: decks,
      totalDecks: decks.length,
      totalCards: totalCards,
      dueCount: dueCards.length,
      newCount: newCount,
      learningCount: learningCount,
      reviewCount: reviewCount,
    );
  }
}
