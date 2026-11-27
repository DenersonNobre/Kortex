import 'package:flutter/material.dart';
import 'package:kortex_br/kortex_br.dart';
import 'package:kortex_forms/kortex_forms.dart';
import 'package:kortex_widgets/kortex_widgets.dart';

void main() => runApp(const MaterialApp(home: _ExamplePage()));

class _ExamplePage extends StatefulWidget {
  const _ExamplePage();

  @override
  State<_ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<_ExamplePage> {
  final _cpf = kortexField<String>('', validators: [CpfValidator.validate]);
  final _phone = kortexField<String>(
    '',
    validators: [PhoneBrValidator.validate],
  );
  final _birthDate = kortexField<DateTime?>(null);

  @override
  void dispose() {
    _cpf.dispose();
    _phone.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_widgets example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            KortexCpfField(field: _cpf),
            const SizedBox(height: 12),
            KortexPhoneBrField(field: _phone),
            const SizedBox(height: 12),
            KortexDateField(field: _birthDate, label: 'Data de nascimento'),
          ],
        ),
      ),
    );
  }
}
