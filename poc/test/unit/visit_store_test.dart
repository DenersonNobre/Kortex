import 'package:poc/core/result.dart';

import '../support/fixtures.dart';

import 'package:poc/modules/visits/data/visit_store.dart';
import 'package:poc/modules/visits/domain/.index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(IResult<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

void main() {
  group('InMemoryVisitStore', () {
    test('save gera ids e listVisits ordena por id', () async {
      final store = InMemoryVisitStore(latency: Duration.zero);

      final first = await store.saveVisit(
        _ok(
          Visit.draft(
            scheduledAt: at(21),
            title: 'A',
            clientId: 1,
            technicianName: 'Ana',
          ),
        ),
      );
      final second = await store.saveVisit(
        _ok(
          Visit.draft(
            scheduledAt: at(21),
            title: 'B',
            clientId: 1,
            technicianName: 'Ana',
          ),
        ),
      );

      expect(first.id, 1);
      expect(second.id, 2);
      expect((await store.listVisits()).map((v) => v.id), [1, 2]);
    });

    test('findVisitById ausente devolve null', () async {
      final store = InMemoryVisitStore(latency: Duration.zero);

      expect(await store.findVisitById(99), isNull);
    });

    test('falha simulada e propagada', () async {
      final store = InMemoryVisitStore(latency: Duration.zero)
        ..failNext = true
        ..error = StateError('offline');

      expect(store.listVisits(), throwsStateError);
    });

    test('falha simulada afeta apenas a proxima operacao', () async {
      final store = InMemoryVisitStore(latency: Duration.zero)..failNext = true;

      await expectLater(store.listVisits(), throwsStateError);
      expect(await store.listVisits(), isEmpty);
    });

    test('deleteVisit remove e ausentes sao no-op', () async {
      final store = InMemoryVisitStore(latency: Duration.zero);
      final visit = await store.saveVisit(
        _ok(
          Visit.draft(
            scheduledAt: at(21),
            title: 'A',
            clientId: 1,
            technicianName: 'Ana',
          ),
        ),
      );

      await store.deleteVisit(visit.id);
      await store.deleteVisit(999);

      expect(await store.listVisits(), isEmpty);
    });
  });
}
