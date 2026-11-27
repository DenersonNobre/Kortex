String appTemplate(String appName) => '''
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
