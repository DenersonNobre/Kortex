String controllerTemplate(String pascal) => '''
import 'package:kortex/kortex.dart';

class ${pascal}Controller extends IKortexController {
  final count = kortexSignal<int>(0);

  ${pascal}Controller() {
    autoDispose(count);
  }
}
''';
