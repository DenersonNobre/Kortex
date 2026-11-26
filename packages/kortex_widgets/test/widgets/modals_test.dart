import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

/// Guarda o futuro do dialog sem achatamento: um helper `async` que
/// retorna `Future<T?>` direto faria o chamador esperar o dialog fechar.
class DialogHandle<T> {
  Future<T?>? result;
}

void main() {
  Future<DialogHandle<T>> open<T>(
    WidgetTester tester,
    WidgetBuilder builder,
  ) async {
    final handle = DialogHandle<T>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                handle.result = showDialog<T>(
                  context: context,
                  builder: builder,
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return handle;
  }

  testWidgets('ConfirmDialog cancela com false', (tester) async {
    final handle = await open<bool>(tester, (_) {
      return const ConfirmDialog(
        title: 'Excluir',
        message: 'Tem certeza?',
        confirmLabel: 'Excluir',
        cancelLabel: 'Cancelar',
      );
    });

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(await handle.result, isFalse);
  });

  testWidgets('ConfirmDialog aplica a cor de confirmacao informada', (
    tester,
  ) async {
    final color = Colors.red.shade700;
    final handle = await open<void>(tester, (_) {
      return ConfirmDialog(
        title: 'Atencao',
        message: 'Operacao irreversivel',
        confirmLabel: 'OK',
        cancelLabel: 'Sair',
        confirmColor: color,
      );
    });

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), color);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await handle.result;
  });

  testWidgets('ModalSheet fecha pelo botao e renderiza icone e filho', (
    tester,
  ) async {
    final handle = await open<void>(tester, (_) {
      return const ModalSheet(
        title: 'Detalhes',
        icon: Icon(Icons.info_outline),
        closeTooltip: 'Fechar modal',
        child: Text('Corpo do modal'),
      );
    });

    expect(find.byType(ModalHeader), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Corpo do modal'), findsOneWidget);
    expect(find.byTooltip('Fechar modal'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar modal'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes'), findsNothing);
    await handle.result;
  });

  testWidgets('ModalSheet sem icone e sem filho renderiza apenas o cabecalho', (
    tester,
  ) async {
    final handle = await open<void>(tester, (_) {
      return const ModalSheet(title: 'Somente cabecalho');
    });

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Somente cabecalho'), findsNothing);
    await handle.result;
  });

  testWidgets('ModalHeader aciona onClose customizado quando informado', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalHeader(
            title: 'Filtro',
            onClose: () => closed++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
  });

  testWidgets('ModalSheet funciona em altura ilimitada sem erro de layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModalSheet(
              title: 'Altura livre',
              child: Text('Conteudo'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Altura livre'), findsOneWidget);
    expect(find.text('Conteudo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
