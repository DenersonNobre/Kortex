String pubspecTemplate(String appName) => '''
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
