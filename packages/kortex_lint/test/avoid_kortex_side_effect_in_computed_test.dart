import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:kortex_lint/src/rules/avoid_kortex_side_effect_in_computed.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidKortexSideEffectInComputed', () {
    test('detects .value assignment inside KortexComputed', () {
      final parsed = parseString(
        content: '''
void example() {
  final c = KortexComputed(() {
    other.value = 1;
    return 2;
  });
}
''',
      );
      expect(parsed.errors, isEmpty);
      final violations = AvoidKortexSideEffectInComputed.findViolations(
        parsed.unit,
      );
      expect(violations, hasLength(1));
    });

    test(
      'detects ++/-- and mutating collection methods inside kortexComputed',
      () {
        final parsed = parseString(
          content: '''
void example() {
  final c = kortexComputed(() {
    other.value++;
    items.add(1);
    return 2;
  });
}
''',
        );
        expect(parsed.errors, isEmpty);
        final violations = AvoidKortexSideEffectInComputed.findViolations(
          parsed.unit,
        );
        expect(violations, hasLength(2));
      },
    );

    test(
      'allows pure read inside KortexComputed and ignores outside mutations',
      () {
        final parsed = parseString(
          content: '''
void example() {
  other.value = 10;
  final c = KortexComputed(() => count.value + 1);
  final nested = KortexComputed(() => () {
    other.value = 1;
  });
}
''',
        );
        expect(parsed.errors, isEmpty);
        final violations = AvoidKortexSideEffectInComputed.findViolations(
          parsed.unit,
        );
        expect(violations, isEmpty);
      },
    );
  });
}
