import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// Barramento reativo global de erros de Edge Functions e Rate Limits
/// equivalente a `lib/services/http/event-bus.ts`.
class EdgeErrorBus extends ChangeNotifier {
  EdgeErrorBus._();

  static final EdgeErrorBus instance = EdgeErrorBus._();

  EdgeError? _latestError;
  RateLimitError? _activeRateLimit;
  Timer? _rateLimitCountdownTimer;
  int _remainingRateLimitSeconds = 0;

  EdgeError? get latestError => _latestError;
  RateLimitError? get activeRateLimit => _activeRateLimit;
  int get remainingRateLimitSeconds => _remainingRateLimitSeconds;

  void emit(Object error) {
    if (error is RateLimitError) {
      _activeRateLimit = error;
      _remainingRateLimitSeconds = error.retryAfterSec;
      _startRateLimitCountdown();
    } else if (error is EdgeError) {
      _latestError = error;
    } else {
      _latestError = EdgeError(
        'unknown',
        0,
        error.toString(),
      );
    }
    notifyListeners();
  }

  void reportException(Object error, {String? endpoint}) {
    emit(error);
  }

  void clear() {
    _latestError = null;
    _activeRateLimit = null;
    _remainingRateLimitSeconds = 0;
    _rateLimitCountdownTimer?.cancel();
    notifyListeners();
  }

  void dismissError() {
    _latestError = null;
    notifyListeners();
  }

  void dismissLatest() {
    dismissError();
    clear();
  }

  void _startRateLimitCountdown() {
    _rateLimitCountdownTimer?.cancel();
    _rateLimitCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRateLimitSeconds <= 1) {
        _remainingRateLimitSeconds = 0;
        _activeRateLimit = null;
        timer.cancel();
      } else {
        _remainingRateLimitSeconds -= 1;
      }
      notifyListeners();
    });
  }
}
