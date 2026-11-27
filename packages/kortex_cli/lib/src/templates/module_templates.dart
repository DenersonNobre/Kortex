/// Templates de scaffolding para modulos e paginas (`kortex module` / `kortex page`).
abstract final class ModuleTemplates {
  static String toPascalCase(String input) => input
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();

  static String controller(String pascal) => '''
import 'package:kortex/kortex.dart';

class ${pascal}Controller extends IKortexController {
  final count = kortexSignal<int>(0);

  ${pascal}Controller() {
    autoDispose(count);
  }
}
''';

  static String page(String pascal, String name) => '''
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '${name}_controller.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<${pascal}Controller>();
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: Center(
        child: KortexWatch(
          builder: (context, _) => Text('Count: \${controller.count.value}'),
        ),
      ),
    );
  }
}
''';

  static String moduleRoutes(String pascal, String moduleName) => '''
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '${moduleName}_controller.dart';
import '${moduleName}_page.dart';

Route<dynamic> build${pascal}Route() {
  return MaterialPageRoute<void>(
    builder: (_) => KortexScope(
      providers: [
        KortexProvider<${pascal}Controller>(create: (_) => ${pascal}Controller()),
      ],
      child: const ${pascal}Page(),
    ),
  );
}
''';

  static String controllerTest(String pascal, String moduleName) => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('${pascal}Controller lifecycle', () {
    expect('$moduleName', isNotEmpty);
  });
}
''';
}
