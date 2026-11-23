import 'package:flutter/material.dart';
import 'package:kortex_lib/kortex_lib.dart';

class DemoController extends IKortexController {
  DemoController() {
    autoDispose(_cpf);
  }

  final _cpf = ''.kortex;
  IKortex<String> get cpf => _cpf.readonly;

  void setCpf(String value) => _cpf.value = value;
}

class DemoPage extends IKortexPage<DemoController> {
  const DemoPage({super.key});

  @override
  Widget buildPage(BuildContext context, DemoController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_lib example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: KortexWatch(
          builder: (context, child) {
            final valid = CpfValidator.isValid(controller.cpf.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  inputFormatters: [CpfInputFormatter()],
                  onChanged: controller.setCpf,
                  decoration: const InputDecoration(labelText: 'CPF'),
                ),
                const SizedBox(height: 8),
                Text(valid ? 'Valid CPF' : 'Enter a valid CPF'),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(
    KortexScope(
      providers: [
        KortexProvider<DemoController>(create: (_) => DemoController()),
      ],
      child: const MaterialApp(home: DemoPage()),
    ),
  );
}
