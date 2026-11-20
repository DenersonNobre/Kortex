import 'package:poc/core/result.dart';
import 'package:poc/modules/visits/data/client_store.dart';
import 'package:poc/modules/visits/data/technician_store.dart';
import 'package:poc/modules/visits/data/visit_store.dart';
import 'package:poc/modules/visits/domain/.index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

void main() {
  group('InMemoryVisitStore', () {
    test('save gera ids e listVisits ordena por id', () async {
      final store = InMemoryVisitStore(latency: Duration.zero);

      final first = await store.saveVisit(
        _ok(Visit.draft(title: 'A', clientId: 1, technicianId: 1)),
      );
      final second = await store.saveVisit(
        _ok(Visit.draft(title: 'B', clientId: 1, technicianId: 1)),
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
        _ok(Visit.draft(title: 'A', clientId: 1, technicianId: 1)),
      );

      await store.deleteVisit(visit.id);
      await store.deleteVisit(999);

      expect(await store.listVisits(), isEmpty);
    });
  });

  group('InMemoryClientStore', () {
    test('save gera id e listClients devolve o cliente', () async {
      final store = InMemoryClientStore(latency: Duration.zero);

      final saved = await store.saveClient(
        _ok(Client.create(name: 'Cliente', phone: '11988887777')),
      );

      expect(saved.id, 1);
      expect((await store.listClients()).single.name, 'Cliente');
      expect(await store.findClientById(saved.id), isNotNull);
    });
  });

  group('InMemoryTechnicianStore', () {
    test('save gera id e listTechnicians devolve o tecnico', () async {
      final store = InMemoryTechnicianStore(latency: Duration.zero);

      final saved = await store.saveTechnician(
        _ok(Technician.create(name: 'Ana', specialty: 'Rede')),
      );

      expect(saved.id, 1);
      expect((await store.listTechnicians()).single.name, 'Ana');
      expect(await store.findTechnicianById(saved.id), isNotNull);
    });
  });
}
