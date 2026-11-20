/// Dialog de nova visita (usa `KortexScope.capture` do `Overlay`).
///
/// SRP: coletar titulo e cliente e agendar no controller do escopo capturado.
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
  var _title = '';
  int? _clientId;

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<VisitsController>();
    return AlertDialog(
      title: const Text('Nova visita'),
      content: KortexWatch(
        builder: (context, child) {
          final clients = controller.clients.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('new-visit-title'),
                initialValue: '',
                decoration: const InputDecoration(labelText: 'Título'),
                onChanged: (value) => _title = value,
              ),
              const SizedBox(height: 12),
              if (clients.isEmpty)
                const Text('Cadastre um cliente antes de agendar.')
              else
                DropdownButtonFormField<int>(
                  key: const Key('new-visit-client'),
                  initialValue: _clientId ?? clients.first.id,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: [
                    for (final client in clients)
                      DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _clientId = value),
                ),
              const SizedBox(height: 12),
              Text(
                'Técnico: ${controller.technicianName}',
                key: const Key('new-visit-technician'),
              ),
            ],
          );
        },
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
    final created = await controller.scheduleVisit(_title, clientId: _clientId);
    if (!created) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
