import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_forms/kortex_forms.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() {
  group('UC-12.06 KortexDateField & KortexDateRangeField', () {
    testWidgets('rejeita data invalida 31/02/2026 sem throw e aceita valida', (
      tester,
    ) async {
      final field = kortexField<DateTime?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: KortexDateField(field: field)),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '31022026');
      await tester.pump();
      expect(find.text('Data invalida'), findsOneWidget);
      expect(field.value, isNull);

      await tester.enterText(find.byType(TextFormField), '25122026');
      await tester.pump();
      expect(find.text('Data invalida'), findsNothing);
      expect(field.value, DateTime(2026, 12, 25));

      field.dispose();
    });

    testWidgets('KortexDateRangeField reprova range com fim < inicio', (
      tester,
    ) async {
      final invalidRange = _FakeDateTimeRange(
        start: DateTime(2026, 5, 10),
        end: DateTime(2026, 5, 5),
      );
      final field = kortexField<DateTimeRange?>(
        invalidRange,
        validators: [KortexDateBr.validateRange],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: KortexDateRangeField(field: field)),
        ),
      );

      expect(
        find.text('Data final deve ser igual ou posterior a inicial'),
        findsOneWidget,
      );
      expect(field.validate(), isFalse);

      field.dispose();
    });
  });
}

class _FakeDateTimeRange implements DateTimeRange {
  _FakeDateTimeRange({required this.start, required this.end});

  @override
  final DateTime start;

  @override
  final DateTime end;

  @override
  Duration get duration => end.difference(start);
}
