import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:kortex_lint/src/rules/avoid_undisposed_kortex_signal.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidUndisposedKortexSignal', () {
    test('exposes expected lint code and metadata', () {
      final rule = AvoidUndisposedKortexSignal();
      expect(rule.name, 'avoid_undisposed_kortex_signal');
      expect(
        rule.diagnosticCode.lowerCaseName,
        'avoid_undisposed_kortex_signal',
      );
    });

    test('parses controller AST cleanly', () {
      final result = parseString(
        content: '''
class MyController extends IKortexController {
  final _count = 0.kortex;
}
''',
      );
      expect(result.errors, isEmpty);
    });
  });
}
