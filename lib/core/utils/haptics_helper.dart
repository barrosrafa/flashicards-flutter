import 'package:flutter/services.dart';

/// Feedback háptico semântico para tornar a sessão de estudo e interações
/// responsivas no Android e iOS.
class HapticsHelper {
  const HapticsHelper._();

  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> onCardFlip() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> onRate(String rating) async {
    switch (rating.toLowerCase()) {
      case 'again':
      case '1':
        await HapticFeedback.heavyImpact();
      case 'hard':
      case '2':
        await HapticFeedback.mediumImpact();
      case 'good':
      case '3':
      case 'easy':
      case '4':
        await HapticFeedback.lightImpact();
      default:
        await HapticFeedback.selectionClick();
    }
  }

  static Future<void> forReviewRating(Object rating) async {
    if (rating is int) {
      await onRate(rating.toString());
    } else {
      await onRate(rating.toString());
    }
  }

  static Future<void> onSessionComplete() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> onError() async {
    await HapticFeedback.vibrate();
  }
}
