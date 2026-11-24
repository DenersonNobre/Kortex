import 'package:flutter_test/flutter_test.dart';
import 'package:poc/core/result.dart';
import 'package:poc/modules/clients/data/.index.dart';
import 'package:poc/modules/clients/domain/.index.dart';
import 'package:poc/modules/session/.index.dart';
import 'package:poc/modules/visits/data/.index.dart';
import 'package:poc/modules/visits/domain/.index.dart';
import 'package:poc/modules/visits/features/visits_features.dart';

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

/// Usuario de sessao valido.
SessionUser _user(String name) =>
    _ok(SessionUser.create(name: name, specialty: 'Rede'));

/// Monta a fachada sobre stores em memoria (sem latencia).
IVisitUseCases _useCases({
  InMemoryVisitStore? visits,
  InMemoryClientStore? clients,
  SessionUser? user,
}) => DefaultVisitUseCases(
  now: () => DateTime(2026, 11, 20, 9, 0),
  visits: visits ?? InMemoryVisitStore(latency: Duration.zero),
  clients: clients ?? InMemoryClientStore(latency: Duration.zero),
  session: InMemorySessionProvider(currentUser: user ?? _user('Ana')),
);

/// Cria um cliente valido.
Future<Client> _client(InMemoryClientStore store) async =>
    store.saveClient(_ok(Client.create(name: 'Cliente', phone: '11988887777')));

void main() {
  group('IVisitUseCases (agendamento)', () {
    test('agenda visita no nome do usuario da sessao', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);

      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca do roteador',
          clientId: client.id,
        ),
      );

      expect(visit.id, isNonZero);
      expect(visit.status, EVisitStatus.scheduled);
      expect(visit.technicianName, 'Ana');
      expect((await visits.listVisits()), hasLength(1));
    });

    test('cada sessao atribui a visita ao seu proprio tecnico', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final ana = _useCases(
        visits: visits,
        clients: clients,
        user: _user('Ana'),
      );
      final bruno = _useCases(
        visits: visits,
        clients: clients,
        user: _user('Bruno'),
      );

      final first = _ok(
        await ana.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Visita da Ana',
          clientId: client.id,
        ),
      );
      final second = _ok(
        await bruno.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 11),
          title: 'Visita do Bruno',
          clientId: client.id,
        ),
      );

      expect(first.technicianName, 'Ana');
      expect(second.technicianName, 'Bruno');
      expect((await ana.listVisits()).map((row) => row.technicianName), [
        'Ana',
        'Bruno',
      ]);
    });

    test('agenda com cliente inexistente falha sem criar visita', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final useCases = _useCases(visits: visits);

      final result = await useCases.scheduleVisit(
        scheduledAt: DateTime(2026, 11, 21, 10),
        title: 'Troca',
        clientId: 99,
      );

      expect(_code(result), ClientFailureCodes.notFound);
      expect(await visits.listVisits(), isEmpty);
    });

    test('titulo vazio falha antes de tocar no repositorio', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final useCases = _useCases(visits: visits);

      final result = await useCases.scheduleVisit(
        scheduledAt: DateTime(2026, 11, 21, 10),
        title: '   ',
        clientId: 1,
      );

      expect(_code(result), VisitFailureCodes.titleEmpty);
      expect(await visits.listVisits(), isEmpty);
    });
  });

  group('IVisitUseCases (ciclo da visita)', () {
    test('inicia visita agendada', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
        ),
      );

      final started = _ok(await useCases.startVisit(visit.id));

      expect(started.status, EVisitStatus.inProgress);
    });

    test('iniciar visita ja iniciada falha e mantem o status', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
        ),
      );
      _ok(await useCases.startVisit(visit.id));

      final result = await useCases.startVisit(visit.id);

      expect(_code(result), VisitFailureCodes.visitAlreadyStarted);
      final stored = await visits.findVisitById(visit.id);
      expect(stored?.status, EVisitStatus.inProgress);
    });

    test('conclui visita em andamento e marca o checklist', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          checklist: [_ok(ChecklistItem.create(description: 'Testar sinal'))],
        ),
      );
      _ok(await useCases.startVisit(visit.id));

      final completed = _ok(await useCases.completeVisit(visit.id));

      expect(completed.status, EVisitStatus.completed);
      expect(completed.checklist.every((item) => item.done), isTrue);
    });

    test('concluir visita agendada falha e mantem o status', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
        ),
      );

      final result = await useCases.completeVisit(visit.id);

      expect(_code(result), VisitFailureCodes.visitNotInProgress);
      final stored = await visits.findVisitById(visit.id);
      expect(stored?.status, EVisitStatus.scheduled);
    });

    test('marca item do checklist', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          checklist: [_ok(ChecklistItem.create(description: 'Testar sinal'))],
        ),
      );
      _ok(await useCases.startVisit(visit.id));

      final toggled = _ok(await useCases.toggleChecklistItem(visit.id, 0));

      expect(toggled.checklist.first.done, isTrue);
      expect(toggled.progress, 1);
    });

    test('visita inexistente falha em qualquer comando', () async {
      final useCases = _useCases();

      expect(
        _code(await useCases.startVisit(99)),
        VisitFailureCodes.visitNotFound,
      );
      expect(
        _code(await useCases.completeVisit(99)),
        VisitFailureCodes.visitNotFound,
      );
      expect(
        _code(await useCases.toggleChecklistItem(99, 0)),
        VisitFailureCodes.visitNotFound,
      );
    });
  });

  group('IVisitUseCases (queries com join)', () {
    test('listagem resolve nome do cliente, do tecnico e progresso', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca do roteador',
          clientId: client.id,
          checklist: [
            _ok(ChecklistItem.create(description: 'A')),
            _ok(ChecklistItem.create(description: 'B')),
          ],
        ),
      );

      final list = await useCases.listVisits();

      expect(list, hasLength(1));
      expect(list.single.clientName, 'Cliente');
      expect(list.single.technicianName, 'Ana');
      expect(list.single.title, 'Troca do roteador');
      expect(list.single.progress, 0);
    });

    test('filtro por status devolve apenas as visitas do status', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      final scheduled = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'A',
          clientId: client.id,
        ),
      );
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'B',
          clientId: client.id,
        ),
      );
      _ok(await useCases.startVisit(scheduled.id));

      final scheduledOnly = await useCases.listVisits(
        status: EVisitStatus.scheduled,
      );
      final inProgress = await useCases.listVisits(
        status: EVisitStatus.inProgress,
      );

      expect(scheduledOnly.map((v) => v.title), ['B']);
      expect(inProgress.map((v) => v.title), ['A']);
    });

    test('filtro por dia devolve apenas as visitas daquele dia', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Dia 21',
          clientId: client.id,
        ),
      );
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 22, 10),
          title: 'Dia 22',
          clientId: client.id,
        ),
      );

      final day = await useCases.listVisits(day: DateTime(2026, 11, 22));

      expect(day.map((v) => v.title), ['Dia 22']);
    });

    test('lista clientes para o formulario', () async {
      final clients = InMemoryClientStore(latency: Duration.zero);
      final useCases = _useCases(clients: clients);
      await _client(clients);

      expect((await useCases.listClients()).single.name, 'Cliente');
    });
  });
}
