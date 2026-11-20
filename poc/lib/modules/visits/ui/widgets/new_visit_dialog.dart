/// Dialog de nova visita (usa `KortexScope.capture` do `Overlay`).
///
/// SRP: coletar titulo e agendar a visita no controller do escopo capturado.
/// NAO faz: regra de negocio nem carga de dados.
///
/// Patterns: `StatefulWidget` de formulario + escopo capturado no dialog.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../visits_controller.dart';

/// Abre o dialog de nova visita herdando o escopo da tela.
Future<void> showNewVisitDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        KortexScope.capture(context: context, child: const NewVisitDialog()),
  );
}

/// Formulario de nova visita.
class NewVisitDialog extends StatefulWidget {
  /// Cria o dialog.
  const NewVisitDialog({super.key});

  @override
  State<NewVisitDialog> createState() => _NewVisitDialogState();
}

class _NewVisitDialogState extends State<NewVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  var _title = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<VisitsController>();
    return AlertDialog(
      title: const Text('Nova visita'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('new-visit-title'),
          initialValue: '',
          decoration: const InputDecoration(labelText: 'Título'),
          onChanged: (value) => _title = value,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('new-visit-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('new-visit-save'),
          onPressed: () => _save(controller),
          child: const Text('Agendar'),
        ),
      ],
    );
  }

  Future<void> _save(VisitsController controller) async {
    final created = await controller.scheduleVisit(_title);
    if (!created) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
