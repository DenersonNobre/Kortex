import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc/app/visits_app.dart';
import 'package:poc/modules/clients/ui/clients_controller.dart';
import 'package:poc/modules/clients/data/.index.dart';
import 'package:poc/modules/clients/features/.index.dart';

/// Fachada sobre store em memoria (sem latencia).
ClientUseCases _useCases([InMemoryClientStore? store]) => DefaultClientUseCases(
  clients: store ?? InMemoryClientStore(latency: Duration.zero),
);

void main() {
  group('ClientsController', () {
    test('carrega a lista e cadastra cliente', () async {
      final controller = ClientsController(_useCases());

      await controller.refresh();
      expect(controller.clients.state.value.valueOrNull, isEmpty);

      final created = await controller.createClient('Empresa X', '11988887777');

      expect(created, isTrue);
      expect(controller.clients.state.value.valueOrNull, hasLength(1));
      expect(
        controller.clients.state.value.valueOrNull!.single.name,
        'Empresa X',
      );
      controller.dispose();
    });

    test('telefone invalido publica erro e nao cadastra', () async {
      final controller = ClientsController(_useCases());
      await controller.refresh();

      final created = await controller.createClient('Empresa X', '1');

      expect(created, isFalse);
      expect(controller.error.value, isNotEmpty);
      expect(controller.clients.state.value.valueOrNull, isEmpty);
      controller.dispose();
    });

    test('busca por nome filtra a lista', () async {
      final controller = ClientsController(_useCases());
      await controller.refresh();
      await controller.createClient('Empresa Alfa', '11988887777');
      await controller.createClient('Beta Ltda', '11977776666');

      controller.search.value = 'alfa';
      await controller.refresh();

      expect(controller.clients.state.value.valueOrNull, hasLength(1));
      expect(
        controller.clients.state.value.valueOrNull!.single.name,
        'Empresa Alfa',
      );
      controller.dispose();
    });
  });

  group('ClientsPage', () {
    testWidgets('lista vazia mostra estado explicito', (tester) async {
      await tester.pumpWidget(createVisitsApp(seedDemo: false));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Clientes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Nenhum cliente'), findsOneWidget);
    });

    testWidgets('cadastra cliente pelo dialog', (tester) async {
      await tester.pumpWidget(createVisitsApp(seedDemo: false));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Clientes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('clients-new')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('client-name')),
        'Empresa Nova',
      );
      await tester.enterText(
        find.byKey(const Key('client-phone')),
        '11955554444',
      );
      await tester.tap(find.byKey(const Key('client-save')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Empresa Nova'), findsOneWidget);
    });
  });
}
