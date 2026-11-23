import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:kortex_lint/src/rules/avoid_kortex_signal_in_build.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidKortexSignalInBuild', () {
    test('exposes expected lint code and metadata', () {
      final rule = AvoidKortexSignalInBuild();
      expect(rule.name, 'avoid_kortex_signal_in_build');
      expect(rule.diagnosticCode.lowerCaseName, 'avoid_kortex_signal_in_build');
    });

    test('parses widget build AST cleanly', () {
      final result = parseString(
        content: '''
class MyPage {
  Object build(Object context) {
    final s = 0.kortex;
    return s;
  }
}
''',
      );
      expect(result.errors, isEmpty);
    });
  });
}
