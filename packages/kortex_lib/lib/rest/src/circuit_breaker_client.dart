import 'package:http/http.dart' as http;

import 'client_decorator_base.dart';

class CircuitOpenException implements Exception {
  const CircuitOpenException({this.message = 'Circuit is open.'});

  final String message;

  @override
  String toString() => message;
}

sealed class CircuitState {
  const CircuitState();
}

final class CircuitClosed extends CircuitState {
  const CircuitClosed([this.consecutiveFailures = 0]);

  final int consecutiveFailures;
}

final class CircuitOpen extends CircuitState {
  const CircuitOpen(this.consecutiveFailures, this.openedAt);

  final int consecutiveFailures;
  final DateTime openedAt;
}

final class CircuitHalfOpen extends CircuitState {
  const CircuitHalfOpen();
}

class CircuitBreakerClient extends ClientDecoratorBase {
  CircuitBreakerClient(
    super.inner, {
    this.failureThreshold = 3,
    this.resetTimeout = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       assert(failureThreshold >= 1);

  final int failureThreshold;
  final Duration resetTimeout;
  final DateTime Function() _clock;
  CircuitState _state = const CircuitClosed();

  CircuitState get state => _state;
  bool get isOpen => _state is CircuitOpen;
  bool get isHalfOpen => _state is CircuitHalfOpen;

  int get consecutiveFailures {
    final current = _state;
    if (current is CircuitClosed) return current.consecutiveFailures;
    if (current is CircuitOpen) return current.consecutiveFailures;
    return 0;
  }

  @override
  void onBefore(http.BaseRequest request) {
    final current = _state;
    if (current is CircuitOpen) {
      if (_clock().difference(current.openedAt) >= resetTimeout) {
        _state = const CircuitHalfOpen();
        return;
      }
      throw const CircuitOpenException();
    }
    if (current is CircuitHalfOpen) {
      throw const CircuitOpenException();
    }
  }

  @override
  void onSuccess(http.BaseRequest request, http.StreamedResponse response) {
    if (response.statusCode >= 500) {
      _recordFailure();
    } else {
      _state = const CircuitClosed();
    }
  }

  @override
  void onError(http.BaseRequest request, Object error) => _recordFailure();

  void _recordFailure() {
    final current = _state;
    if (current is CircuitOpen) return;
    if (current is CircuitHalfOpen) {
      _state = CircuitOpen(1, _clock());
      return;
    }
    final closed = current as CircuitClosed;
    final failures = closed.consecutiveFailures + 1;
    _state = failures >= failureThreshold
        ? CircuitOpen(failures, _clock())
        : CircuitClosed(failures);
  }
}
