/// Pure-Dart CLI for scaffolding Kortex apps and modules.
library;

import 'dart:io';

/// Executes the `kortex` CLI with [args] in [workingDirectory].
int runKortexCli(List<String> args, Directory workingDirectory) {
  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    _printUsage();
    return 0;
  }

  final command = args.first;
  if (command == 'create' && args.length >= 2) {
    return _createApp(args[1], workingDirectory);
  }
  if (command == 'module' && args.length >= 2) {
    return _createModule(args[1], workingDirectory);
  }
  if (command == 'page' && args.length >= 3) {
    return _createPage(args[1], args[2], workingDirectory);
  }

  stderr.writeln('Comando invalido: ${args.join(' ')}');
  _printUsage();
  return 64;
}

void _printUsage() {
  stdout.writeln('kortex_cli — Scaffolding para apps Kortex');
  stdout.writeln('');
  stdout.writeln('Uso:');
  stdout.writeln('  kortex create <app_name>             Cria estrutura base em <app_name>/');
  stdout.writeln('  kortex module <module_name>          Cria fatia vertical em lib/modules/<module_name>/');
  stdout.writeln('  kortex page <module_name> <page>     Cria page + controller em lib/modules/<module_name>/ui/');
  stdout.writeln('  kortex help                          Exibe esta ajuda');
}

int _createApp(String appName, Directory workingDirectory) {
  final root = Directory('${workingDirectory.path}${Platform.pathSeparator}$appName');
  _write(root, 'pubspec.yaml', _pubspecTemplate(appName));
  _write(root, 'lib/main.dart', _mainTemplate());
  _write(root, 'lib/app/app.dart', _appTemplate(appName));
  _write(root, 'lib/app/routes/app_routes.dart', _appRoutesTemplate());
  _write(root, 'lib/app/routes/app_pages.dart', _appPagesTemplate());
  _write(root, 'test/widget_test.dart', _appTestTemplate());
  Directory('${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}core')
      .createSync(recursive: true);
  Directory('${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}modules')
      .createSync(recursive: true);
  stdout.writeln('App "$appName" criado em ${root.path}');
  return 0;
}

int _createModule(String moduleName, Directory workingDirectory) {
  final pascal = _toPascalCase(moduleName);
  final base = 'lib/modules/$moduleName';
  _write(
    workingDirectory,
    '$base/ui/${moduleName}_controller.dart',
    _controllerTemplate(pascal),
  );
  _write(
    workingDirectory,
    '$base/ui/${moduleName}_page.dart',
    _pageTemplate(pascal, moduleName),
  );
  _write(
    workingDirectory,
    '$base/ui/${moduleName}_routes.dart',
    _moduleRoutesTemplate(pascal, moduleName),
  );
  _write(
    workingDirectory,
    'test/modules/$moduleName/${moduleName}_controller_test.dart',
    _controllerTestTemplate(pascal, moduleName),
  );
  for (final sub in ['domain', 'data', 'features']) {
    Directory(
      '${workingDirectory.path}${Platform.pathSeparator}$base${Platform.pathSeparator}$sub',
    ).createSync(recursive: true);
  }
  stdout.writeln('Modulo "$moduleName" criado em $base');
  return 0;
}

int _createPage(String moduleName, String pageName, Directory workingDirectory) {
  final pascal = _toPascalCase(pageName);
  final base = 'lib/modules/$moduleName/ui';
  _write(
    workingDirectory,
    '$base/${pageName}_controller.dart',
    _controllerTemplate(pascal),
  );
  _write(
    workingDirectory,
    '$base/${pageName}_page.dart',
    _pageTemplate(pascal, pageName),
  );
  stdout.writeln('Page "$pageName" criada em $base');
  return 0;
}

void _write(Directory root, String relativePath, String content) {
  final file = File(
    '${root.path}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _toPascalCase(String input) => input
    .split(RegExp(r'[_\-\s]+'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join();

String _mainTemplate() => '''
import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
''';

String _appTemplate(String appName) => '''
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

String _appRoutesTemplate() => '''
abstract final class AppRoutes {
  static const initial = '/';
}
''';

String _appPagesTemplate() => '''
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

String _controllerTemplate(String pascal) => '''
import 'package:kortex/kortex.dart';

class ${pascal}Controller extends IKortexController {
  final count = kortexSignal<int>(0);

  ${pascal}Controller() {
    autoDispose(count);
  }
}
''';

String _pageTemplate(String pascal, String moduleName) => '''
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '${moduleName}_controller.dart';

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

String _moduleRoutesTemplate(String pascal, String moduleName) => '''
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

String _pubspecTemplate(String appName) => '''
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

String _appTestTemplate() => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke test', () {
    expect(1 + 1, 2);
  });
}
''';

String _controllerTestTemplate(String pascal, String moduleName) => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('${pascal}Controller lifecycle', () {
    expect('$moduleName', isNotEmpty);
  });
}
''';
