import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  testWidgets('KortexCpfField aplica mascara e exibe erro de validacao', (
    tester,
  ) async {
    final field = kortexField<String>('', validators: [CpfValidator.validate]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KortexCpfField(field: field)),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '52998224725');
    await tester.pump();
    expect(field.value, '529.982.247-25');
    expect(field.validate(), isTrue);

    await tester.enterText(find.byType(TextFormField), '11111111111');
    await tester.pump();
    expect(field.validate(), isFalse);
    await tester.pump();
    expect(find.text('CPF invalido'), findsOneWidget);

    field.dispose();
  });
}
