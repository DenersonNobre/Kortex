import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:kortex_lint/src/rules/prefer_i_prefix_for_abstractions.dart';
import 'package:test/test.dart';

void main() {
  group('PreferIPrefixForAbstractions', () {
    test('exposes expected lint code and metadata', () {
      final rule = PreferIPrefixForAbstractions();
      expect(rule.name, 'prefer_i_prefix_for_abstractions');
      expect(
        rule.diagnosticCode.lowerCaseName,
        'prefer_i_prefix_for_abstractions',
      );
    });

    test('parses abstraction AST cleanly', () {
      final result = parseString(
        content: '''
sealed class Result<T> {}
abstract interface class IStorage {}
''',
      );
      expect(result.errors, isEmpty);
    });
  });
}
