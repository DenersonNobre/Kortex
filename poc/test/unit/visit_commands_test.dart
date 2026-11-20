import 'package:poc/core/result.dart';
import 'package:poc/modules/visits/data/.index.dart';
import 'package:poc/modules/visits/domain/.index.dart';
import 'package:poc/modules/visits/features/visit_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// Codigo de um `Fail` (falha o teste se for `Ok`).
String _code<T>(Result<T> result) {
  expect(result, isA<Fail<T>>());
  return (result as Fail).code;
}

/// Monta a fachada sobre stores em memoria (sem latencia).
VisitUseCases _useCases({
  InMemoryVisitStore? visits,
  InMemoryClientStore? clients,
  InMemoryTechnicianStore? technicians,
}) => DefaultVisitUseCases(
  now: () => DateTime(2026, 11, 20, 9, 0),
  visits: visits ?? InMemoryVisitStore(latency: Duration.zero),
  clients: clients ?? InMemoryClientStore(latency: Duration.zero),
  technicians: technicians ?? InMemoryTechnicianStore(latency: Duration.zero),
);

/// Cria um cliente valido.
Future<Client> _client(InMemoryClientStore store) async =>
    store.saveClient(_ok(Client.create(name: 'Cliente', phone: '11988887777')));

/// Cria um tecnico valido.
Future<Technician> _technician(InMemoryTechnicianStore store) async => store
    .saveTechnician(_ok(Technician.create(name: 'Ana', specialty: 'Rede')));

void main() {
  group('VisitUseCases (agendamento)', () {
    test('agenda visita com cliente e tecnico existentes', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );

      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca do roteador',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );

      expect(visit.id, isNonZero);
      expect(visit.status, VisitStatus.scheduled);
      expect((await visits.listVisits()), hasLength(1));
    });

    test('agenda com cliente inexistente falha sem criar visita', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final useCases = _useCases(visits: visits);

      final result = await useCases.scheduleVisit(
        scheduledAt: DateTime(2026, 11, 21, 10),
        title: 'Troca',
        clientId: 99,
        technicianId: 1,
      );

      expect(_code(result), VisitFailureCodes.clientNotFound);
      expect(await visits.listVisits(), isEmpty);
    });

    test('agenda com tecnico inexistente falha sem criar visita', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final client = await _client(clients);
      final useCases = _useCases(visits: visits, clients: clients);

      final result = await useCases.scheduleVisit(
        scheduledAt: DateTime(2026, 11, 21, 10),
        title: 'Troca',
        clientId: client.id,
        technicianId: 99,
      );

      expect(_code(result), VisitFailureCodes.technicianNotFound);
      expect(await visits.listVisits(), isEmpty);
    });

    test('titulo vazio falha antes de tocar no repositorio', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final useCases = _useCases(visits: visits);

      final result = await useCases.scheduleVisit(
        scheduledAt: DateTime(2026, 11, 21, 10),
        title: '   ',
        clientId: 1,
        technicianId: 1,
      );

      expect(_code(result), VisitFailureCodes.titleEmpty);
      expect(await visits.listVisits(), isEmpty);
    });
  });

  group('VisitUseCases (ciclo da visita)', () {
    test('inicia visita agendada', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );

      final started = _ok(await useCases.startVisit(visit.id));

      expect(started.status, VisitStatus.inProgress);
    });

    test('iniciar visita ja iniciada falha e mantem o status', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );
      _ok(await useCases.startVisit(visit.id));

      final result = await useCases.startVisit(visit.id);

      expect(_code(result), VisitFailureCodes.visitAlreadyStarted);
      final stored = await visits.findVisitById(visit.id);
      expect(stored?.status, VisitStatus.inProgress);
    });

    test('conclui visita em andamento e marca o checklist', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          technicianId: technician.id,
          checklist: [_ok(ChecklistItem.create(description: 'Testar sinal'))],
        ),
      );
      _ok(await useCases.startVisit(visit.id));

      final completed = _ok(await useCases.completeVisit(visit.id));

      expect(completed.status, VisitStatus.completed);
      expect(completed.checklist.every((item) => item.done), isTrue);
    });

    test('concluir visita agendada falha e mantem o status', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );

      final result = await useCases.completeVisit(visit.id);

      expect(_code(result), VisitFailureCodes.visitNotInProgress);
      final stored = await visits.findVisitById(visit.id);
      expect(stored?.status, VisitStatus.scheduled);
    });

    test('marca item do checklist', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final visit = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca',
          clientId: client.id,
          technicianId: technician.id,
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

  group('VisitUseCases (queries com join)', () {
    test('listagem resolve nome do cliente, do tecnico e progresso', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero);
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'Troca do roteador',
          clientId: client.id,
          technicianId: technician.id,
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
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final client = await _client(clients);
      final technician = await _technician(technicians);
      final useCases = _useCases(
        visits: visits,
        clients: clients,
        technicians: technicians,
      );
      final scheduled = _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'A',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );
      _ok(
        await useCases.scheduleVisit(
          scheduledAt: DateTime(2026, 11, 21, 10),
          title: 'B',
          clientId: client.id,
          technicianId: technician.id,
        ),
      );
      _ok(await useCases.startVisit(scheduled.id));

      final scheduledOnly = await useCases.listVisits(
        status: VisitStatus.scheduled,
      );
      final inProgress = await useCases.listVisits(
        status: VisitStatus.inProgress,
      );

      expect(scheduledOnly.map((v) => v.title), ['B']);
      expect(inProgress.map((v) => v.title), ['A']);
    });

    test('lista clientes e tecnicos', () async {
      final clients = InMemoryClientStore(latency: Duration.zero);
      final technicians = InMemoryTechnicianStore(latency: Duration.zero);
      final useCases = _useCases(clients: clients, technicians: technicians);
      await _client(clients);
      await _technician(technicians);

      expect((await useCases.listClients()).single.name, 'Cliente');
      expect((await useCases.listTechnicians()).single.name, 'Ana');
    });
  });

  group('VisitUseCases (cadastros)', () {
    test('cria cliente e tecnico', () async {
      final useCases = _useCases();

      final client = _ok(
        await useCases.createClient(name: 'Empresa X', phone: '11988887777'),
      );
      final technician = _ok(
        await useCases.createTechnician(name: 'Bruno', specialty: 'Software'),
      );

      expect(client.id, isNonZero);
      expect(technician.id, isNonZero);
      expect((await useCases.listClients()), hasLength(1));
    });

    test('cliente com telefone invalido falha', () async {
      final useCases = _useCases();

      final result = await useCases.createClient(name: 'Empresa X', phone: '1');

      expect(_code(result), VisitFailureCodes.clientPhoneInvalid);
      expect(await useCases.listClients(), isEmpty);
    });
  });
}
