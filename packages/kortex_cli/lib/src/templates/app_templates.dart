/// Templates de scaffolding para o app base (`kortex create`).
abstract final class AppTemplates {
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
}
