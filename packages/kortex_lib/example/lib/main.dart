import 'package:flutter/material.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() => runApp(const MaterialApp(home: DemoPage()));

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final field = kortexField<String>(
      '',
      validators: [kortexValidator<String>().required('Obrigatorio').build()],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_lib example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Campo valido: ${field.isValid}'),
      ),
    );
  }
}
