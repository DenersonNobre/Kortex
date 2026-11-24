import 'package:flutter_test/flutter_test.dart';
import 'package:poc/core/result.dart';
import 'package:poc/modules/visits/domain/.index.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(AppResult<T> result) {
  expect(result, isA<Success<T, AppFailure>>());
  return (result as Success<T, AppFailure>).value;
}

/// Codigo de um `Fail` (falha o teste se for `Ok`).
String _code<T>(AppResult<T> result) {
  expect(result, isA<Failure<T, AppFailure>>());
  return (result as Failure<T, AppFailure>).code;
}

void main() {
  final now = DateTime(2026, 11, 20, 10, 30);

  group('ScheduledAt (VO)', () {
    test('data futura aprova normalizando ao minuto', () {
      final scheduled = _ok(
        ScheduledAt.create(DateTime(2026, 11, 21, 14, 45, 30), now: now),
      );

      expect(scheduled.value, DateTime(2026, 11, 21, 14, 45));
      expect(scheduled.value.second, 0);
      expect(scheduled.value.millisecond, 0);
    });

    test('data no passado reprova com VISIT_IN_PAST', () {
      final result = ScheduledAt.create(DateTime(2026, 11, 20, 9, 0), now: now);

      expect(_code(result), VisitFailureCodes.scheduledInPast);
    });

    test('data igual a agora reprova (nao agenda no proprio instante)', () {
      final result = ScheduledAt.create(now, now: now);

      expect(_code(result), VisitFailureCodes.scheduledInPast);
    });

    test('permite agendar para daqui a 1 minuto', () {
      final scheduled = _ok(
        ScheduledAt.create(now.add(const Duration(minutes: 1)), now: now),
      );

      expect(scheduled.value, DateTime(2026, 11, 20, 10, 31));
    });
  });

  group('Visit com data agendada', () {
    test('draft exige scheduledAt e guarda o valor', () {
      final visit = _ok(
        Visit.draft(
          title: 'Troca do roteador',
          clientId: 1,
          technicianName: 'Ana',
          scheduledAt: _ok(
            ScheduledAt.create(DateTime(2026, 11, 21, 14, 45), now: now),
          ),
        ),
      );

      expect(visit.scheduledAt.value, DateTime(2026, 11, 21, 14, 45));
    });

    test('withId/withStatus preservam scheduledAt', () {
      final visit = _ok(
        Visit.draft(
          title: 'Troca',
          clientId: 1,
          technicianName: 'Ana',
          scheduledAt: _ok(
            ScheduledAt.create(DateTime(2026, 11, 21, 8, 0), now: now),
          ),
        ),
      );

      final moved = visit.withId(7).withStatus(EVisitStatus.inProgress);

      expect(moved.scheduledAt.value, DateTime(2026, 11, 21, 8, 0));
    });
  });
}
