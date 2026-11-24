import 'package:poc/core/result.dart';
import 'package:poc/modules/visits/domain/.index.dart';

/// "Agora" fixo dos testes de dominio (determinismo).
final DateTime testNow = DateTime(2026, 11, 20, 9, 0);

/// Cria um `ScheduledAt` valido no dia [day] de novembro/2026.
ScheduledAt at(int day, {int hour = 10, int minute = 0}) {
  final result = ScheduledAt.create(
    DateTime(2026, 11, day, hour, minute),
    now: testNow,
  );
  if (result is Success<ScheduledAt, AppFailure>) {
    return result.value;
  }
  throw StateError('fixture invalida: dia $day nao e futuro');
}
