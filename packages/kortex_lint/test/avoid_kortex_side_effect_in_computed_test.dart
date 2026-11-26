import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:kortex_lint/src/rules/avoid_kortex_side_effect_in_computed.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidKortexSideEffectInComputed', () {
    test('exposes stable lint code and correction message', () {
      final rule = AvoidKortexSideEffectInComputed();
      expect(rule.name, 'avoid_kortex_side_effect_in_computed');
      expect(
        rule.diagnosticCode.correctionMessage,
        contains('KortexComputed pure'),
      );
    });

    test('parses KortexComputed AST without errors', () {
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
    });
  });
}
