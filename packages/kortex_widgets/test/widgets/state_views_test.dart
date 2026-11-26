import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('ErrorRetryView exibe mensagem e dispara o retry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      wrap(
        ErrorRetryView(
          message: 'Falha ao carregar',
          onRetry: () => retried++,
          retryTooltip: 'Tentar de novo',
        ),
      ),
    );

    expect(find.text('Falha ao carregar'), findsOneWidget);
    await tester.tap(find.byTooltip('Tentar de novo'));
    expect(retried, 1);
  });

  testWidgets('ErrorRetryView omite botao quando nao ha onRetry', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ErrorRetryView(message: 'Erro')));

    expect(find.text('Erro'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('ErrorRetryView usa o icone customizado informado', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const ErrorRetryView(icon: Icons.warning_amber_outlined)),
    );

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('EmptyState executa a acao quando presente', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        EmptyState(
          title: 'Sem resultados',
          message: 'Ajuste os filtros',
          action: TextButton(
            onPressed: () => pressed++,
            child: const Text('Limpar filtros'),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Ajuste os filtros'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    expect(pressed, 1);
  });

  testWidgets('Loading renderiza o rotulo informado', (
    tester,
  ) async {
    const label = 'Carregando dados';

    await tester.pumpWidget(
      wrap(const Loading(label: label)),
    );

    expect(find.text(label), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
