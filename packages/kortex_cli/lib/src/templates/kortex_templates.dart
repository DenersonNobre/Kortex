/// Templates de scaffolding para apps e modulos Kortex.
abstract final class KortexTemplates {
  static String toPascalCase(String input) => input
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();

  static String pubspec(String appName) => '''
name: $appName
publish_to: none

environment:
  sdk: ^3.13.5

dependencies:
  flutter:
    sdk: flutter
  kortex: ^0.2.3
  kortex_core: ^0.1.0
  kortex_widgets: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''';

  static String main() => '''
import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
''';

  static String app(String appName) => '''
import 'package:flutter/material.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName',
      initialRoute: AppRoutes.initial,
      onGenerateRoute: AppPages.onGenerateRoute,
    );
  }
}
''';

  static String appRoutes() => '''
abstract final class AppRoutes {
  static const initial = '/';
}
''';

  static String appPages() => '''
import 'package:flutter/material.dart';

import 'app_routes.dart';

abstract final class AppPages {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.initial => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Kortex App')),
          ),
        ),
      _ => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Rota nao encontrada')),
          ),
        ),
    };
  }
}
''';

  static String appTest() => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke test', () {
    expect(1 + 1, 2);
  });
}
''';

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
