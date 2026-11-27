String appPagesTemplate() => '''
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
