import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  group('CommandBuilder', () {
    testWidgets(
      'exibe Loading por padrao quando o comando ainda nao executou',
      (tester) async {
        final command = Command<String, String, void>(
          (_) async => const Success('ok'),
          mapException: (e, s) => '$e',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandBuilder<String, String, void>(
                command: command,
                builder: (context, data) => Text('Dado: $data'),
              ),
            ),
          ),
        );

        expect(find.byType(Loading), findsOneWidget);
        expect(find.text('Dado: ok'), findsNothing);
      },
    );

    testWidgets('exibe resultado do builder quando o comando obtém sucesso', (
      tester,
    ) async {
      final command = Command<String, String, void>(
        (_) async => const Success('conteudo carregado'),
        mapException: (e, s) => '$e',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandBuilder<String, String, void>(
              command: command,
              builder: (context, data) => Text('Sucesso: $data'),
            ),
          ),
        ),
      );

      await command.run();
      await tester.pump();

      expect(find.text('Sucesso: conteudo carregado'), findsOneWidget);
      expect(find.byType(Loading), findsNothing);
    });

    testWidgets(
      'exibe ErrorRetryView por padrao quando falha e permite retry',
      (tester) async {
        var tentativas = 0;
        final command = Command<String, String, void>((_) async {
          tentativas++;
          if (tentativas == 1) {
            return const Failure('Falha na conexao');
          }
          return const Success('Recuperado');
        }, mapException: (e, s) => '$e');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandBuilder<String, String, void>(
                command: command,
                builder: (context, data) => Text('Resultado: $data'),
              ),
            ),
          ),
        );

        await command.run();
        await tester.pump();

        expect(find.byType(ErrorRetryView), findsOneWidget);
        expect(find.text('Falha na conexao'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(tentativas, 2);
        expect(find.text('Resultado: Recuperado'), findsOneWidget);
      },
    );

    testWidgets('permite customizar errorBuilder e loadingBuilder', (
      tester,
    ) async {
      final command = Command<String, String, void>(
        (_) async => const Failure('Erro customizado'),
        mapException: (e, s) => '$e',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandBuilder<String, String, void>(
              command: command,
              loadingBuilder: (context) =>
                  const Text('Carregando customizado...'),
              errorBuilder: (context, fail) => Text('Erro: $fail'),
              builder: (context, data) => Text('Dado: $data'),
            ),
          ),
        ),
      );

      expect(find.text('Carregando customizado...'), findsOneWidget);

      await command.run();
      await tester.pump();

      expect(find.text('Erro: Erro customizado'), findsOneWidget);
    });
  });
}
