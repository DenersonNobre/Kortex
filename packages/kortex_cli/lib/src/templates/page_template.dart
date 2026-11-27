String pageTemplate(String pascal, String name) => '''
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
