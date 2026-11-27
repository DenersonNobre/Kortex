String moduleRoutesTemplate(String pascal, String moduleName) => '''
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
