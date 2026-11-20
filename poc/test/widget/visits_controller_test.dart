import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:poc/modules/visits/data/.index.dart';
import 'package:poc/modules/visits/features/visit_use_cases.dart';
import 'package:poc/modules/visits/ui/visits_controller.dart';

/// Monta a fachada sobre stores em memoria (sem latencia, para teste).
VisitUseCases _useCases() => DefaultVisitUseCases(
  visits: InMemoryVisitStore(latency: Duration.zero),
  clients: InMemoryClientStore(latency: Duration.zero),
  technicians: InMemoryTechnicianStore(latency: Duration.zero),
);

void main() {
  group('VisitsController', () {
    test('carrega a lista no refresh e expõe isLoading', () async {
      final controller = VisitsController(_useCases());

      expect(controller.visits.state.value.isLoading, isTrue);

      await controller.refresh();

      expect(controller.visits.state.value, isA<KortexAsyncData>());
      expect(controller.visits.state.value.valueOrNull, isEmpty);
      controller.dispose();
    });

    test('agenda visita e recarrega a lista', () async {
      final controller = VisitsController(_useCases());
      final client = controller.clients.value;
      expect(client, isEmpty);

      await controller.refresh();

      final created = await controller.createClient('Empresa X', '11988887777');
      expect(created, isTrue);
      final technician = await controller.createTechnician('Ana', 'Rede');
      expect(technician, isTrue);

      final scheduled = await controller.scheduleVisit('Troca do roteador');
      expect(scheduled, isTrue);

      final rows = controller.visits.state.value.valueOrNull;
      expect(rows, hasLength(1));
      expect(rows!.single.clientName, 'Empresa X');
      controller.dispose();
    });

    test('falha de negocio vira mensagem de erro', () async {
      final controller = VisitsController(_useCases());
      await controller.refresh();

      final created = await controller.scheduleVisit('   ');

      expect(created, isFalse);
      expect(controller.error.value, isNotEmpty);
      controller.dispose();
    });

    test('inicia visita e atualiza o status na lista', () async {
      final controller = VisitsController(_useCases());
      await controller.refresh();
      await controller.createClient('Empresa X', '11988887777');
      await controller.createTechnician('Ana', 'Rede');
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
      final controller = VisitsController(_useCases());
      await controller.refresh();

      await controller.applyStatusFilter('in_progress');

      expect(controller.statusFilter.value, 'in_progress');
      expect(controller.visits.state.value.valueOrNull, isEmpty);
      controller.dispose();
    });

    test('erro de infraestrutura vira KortexAsyncError na lista', () async {
      final visits = InMemoryVisitStore(latency: Duration.zero)
        ..failNext = true;
      final controller = VisitsController(
        DefaultVisitUseCases(
          visits: visits,
          clients: InMemoryClientStore(latency: Duration.zero),
          technicians: InMemoryTechnicianStore(latency: Duration.zero),
        ),
      );

      await controller.refresh();

      expect(controller.visits.state.value, isA<KortexAsyncError>());
      controller.dispose();
    });
  });
}
