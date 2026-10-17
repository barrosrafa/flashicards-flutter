import 'package:flutter/services.dart';

/// Feedback háptico semântico para tornar a sessão de estudo e interações
/// responsivas no Android e iOS.
class HapticsHelper {
  const HapticsHelper._();

  static Future<void> onCardFlip() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> onRate(String rating) async {
    switch (rating) {
      case 'again':
        await HapticFeedback.heavyImpact();
      case 'hard':
        await HapticFeedback.mediumImpact();
      case 'good':
      case 'easy':
        await HapticFeedback.lightImpact();
      default:
        await HapticFeedback.selectionClick();
    }
  }

  static Future<void> onSessionComplete() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> onError() async {
    await HapticFeedback.vibrate();
  }
}
