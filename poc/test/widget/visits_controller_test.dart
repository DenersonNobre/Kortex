import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:poc/core/result.dart';
import 'package:poc/modules/clients/data/.index.dart';
import 'package:poc/modules/clients/domain/.index.dart';
import 'package:poc/modules/session/.index.dart';
import 'package:poc/modules/visits/data/.index.dart';
import 'package:poc/modules/visits/features/visits_features.dart';
import 'package:poc/modules/visits/ui/visits_controller.dart';

import '../support/controller_lifecycle.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(IResult<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// Fachada sobre stores em memoria (sem latencia, para teste).
IVisitUseCases _useCases({
  InMemoryVisitStore? visits,
  InMemoryClientStore? clients,
}) => DefaultVisitUseCases(
  visits: visits ?? InMemoryVisitStore(latency: Duration.zero),
  clients: clients ?? InMemoryClientStore(latency: Duration.zero),
  session: InMemorySessionProvider.demo(),
);

/// Controller com o cliente de demonstracao ja' cadastrado.
VisitsController _controllerWithClient() => track(
  VisitsController(
    _useCases(
      clients: InMemoryClientStore(latency: Duration.zero, seedDemo: true),
    ),
  ),
);

void main() {
  group('VisitsController', () {
    test('carrega a lista no refresh e expõe isLoading', () async {
      final controller = track(VisitsController(_useCases()));

      expect(controller.visits.state.value.isLoading, isTrue);

      await controller.refresh();

      expect(controller.visits.state.value, isA<KortexAsyncData>());
      expect(controller.visits.state.value.valueOrNull, isEmpty);
      controller.dispose();
    });

    test('agenda visita no nome do tecnico da sessao', () async {
      final controller = _controllerWithClient();
      expect(controller.clients.value, isEmpty);

      await controller.loadClients();
      expect(controller.clients.value, hasLength(1));
      expect(controller.technicianName, 'Tecnico Demo');

      final scheduled = await controller.scheduleVisit('Troca do roteador');
      expect(scheduled, isTrue);

      final rows = controller.visits.state.value.valueOrNull;
      expect(rows, hasLength(1));
      expect(rows!.single.clientName, 'Cliente Demo');
      expect(rows.single.technicianName, 'Tecnico Demo');
      controller.dispose();
    });

    test('agenda para o cliente escolhido', () async {
      final clients = InMemoryClientStore(
        latency: Duration.zero,
        seedDemo: true,
      );
      final extra = await clients.saveClient(
        _ok(Client.create(name: 'Segundo', phone: '11977776666')),
      );
      final controller = VisitsController(_useCases(clients: clients));
      await controller.loadClients();

      final scheduled = await controller.scheduleVisit(
        'Visita do segundo cliente',
        clientId: extra.id,
      );

      expect(scheduled, isTrue);
      expect(
        controller.visits.state.value.valueOrNull!.single.clientName,
        'Segundo',
      );
      controller.dispose();
    });

    test('sem cliente cadastrado publica erro e nao agenda', () async {
      final controller = track(VisitsController(_useCases()));
      await controller.loadClients();

      final scheduled = await controller.scheduleVisit('Troca');

      expect(scheduled, isFalse);
      expect(controller.error.value, isNotEmpty);
      controller.dispose();
    });

    test('falha de negocio vira mensagem de erro', () async {
      final controller = _controllerWithClient();
      await controller.loadClients();

      final created = await controller.scheduleVisit('   ');

      expect(created, isFalse);
      expect(controller.error.value, isNotEmpty);
      controller.dispose();
    });

    test('inicia visita e atualiza o status na lista', () async {
      final controller = _controllerWithClient();
      await controller.loadClients();
      await controller.scheduleVisit('Troca');
      final visitId = controller.visits.state.value.valueOrNull!.single.id;

      final started = await controller.startVisit(visitId);

      expect(started, isTrue);
      expect(
        controller.visits.state.value.valueOrNull!.single.status,
        'in_progress',
      );
      controller.dispose();
    });

    test('filtro por status recarrega a lista', () async {
      final controller = track(VisitsController(_useCases()));
      await controller.refresh();

      await controller.applyStatusFilter('in_progress');

      expect(controller.statusFilter.value, 'in_progress');
      expect(controller.visits.state.value.valueOrNull, isEmpty);
      controller.dispose();
    });

    test('erro de infraestrutura vira KortexAsyncError na lista', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero)
        ..failNext = true;
      final controller = track(VisitsController(_useCases(visits: visits)));

      await controller.refresh();

      expect(controller.visits.state.value, isA<KortexAsyncError>());
      controller.dispose();
    });
  });
}
