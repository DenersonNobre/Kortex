String controllerTestTemplate(String pascal, String moduleName) => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('${pascal}Controller lifecycle', () {
    expect('$moduleName', isNotEmpty);
  });
}
''';
