import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  Widget testApp({required WidgetBuilder builder}) {
    return MaterialApp(
      home: Scaffold(body: Builder(builder: builder)),
    );
  }

  group('Alert widget tests', () {
    testWidgets('error exibe SnackBar com título e mensagem', (tester) async {
      await tester.pumpWidget(
        testApp(
          builder: (context) => ElevatedButton(
            onPressed: () => Alert.error(
              context,
              title: 'Erro de validação',
              message: 'Campo obrigatório',
            ),
            child: const Text('Disparar'),
          ),
        ),
      );

      await tester.tap(find.text('Disparar'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erro de validação\nCampo obrigatório'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('success exibe SnackBar de sucesso', (tester) async {
      await tester.pumpWidget(
        testApp(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Alert.success(context, message: 'Salvo com sucesso'),
            child: const Text('Salvar'),
          ),
        ),
      );

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sucesso\nSalvo com sucesso'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('info e warning exibem mensagens correspondentes', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () =>
                    Alert.info(context, message: 'Dica do sistema'),
                child: const Text('Info'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Alert.warning(context, message: 'Atenção aos prazos'),
                child: const Text('Aviso'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Info'));
      await tester.pump();
      expect(find.text('Informação\nDica do sistema'), findsOneWidget);

      await tester.tap(find.text('Aviso'));
      await tester.pump();
      expect(find.text('Atenção\nAtenção aos prazos'), findsOneWidget);
    });

    testWidgets('created, updated e deleted executam sem erro', (tester) async {
      await tester.pumpWidget(
        testApp(
          builder: (context) => ElevatedButton(
            onPressed: () => Alert.deleted(context),
            child: const Text('Excluir'),
          ),
        ),
      );

      await tester.tap(find.text('Excluir'));
      await tester.pump();

      expect(
        find.text('Exclusão\nRegistro excluído com sucesso'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
