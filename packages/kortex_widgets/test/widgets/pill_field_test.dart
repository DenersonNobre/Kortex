import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  testWidgets('PillField usa tema e permite configurar raio e erro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const Scaffold(
          body: PillField(
            label: 'E-mail',
            error: 'Informe um e-mail',
            borderRadius: 16,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final border = field.decoration!.border as OutlineInputBorder;

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Informe um e-mail'), findsOneWidget);
    expect(border.borderRadius, BorderRadius.circular(16));
    expect(field.decoration!.filled, isTrue);
  });

  testWidgets('PillField exibe prefixo e delega a submissao', (tester) async {
    var submitted = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PillField(
            label: 'Senha',
            icon: Icons.lock_outline,
            onSubmitted: () => submitted++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'segredo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 1);
  });

  testWidgets(
    'PillField respeita readOnly, inputFormatters, maxLength e onTap',
    (tester) async {
      var tapped = 0;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillField(
              controller: controller,
              label: 'Quantidade',
              readOnly: false,
              maxLength: 5,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isFalse);
      expect(textField.maxLength, 5);
      expect(textField.decoration!.counterText, '');

      await tester.tap(find.byType(TextField));
      expect(tapped, 1);

      await tester.enterText(find.byType(TextField), 'abc123456');
      expect(controller.text, '12345');
    },
  );
}
