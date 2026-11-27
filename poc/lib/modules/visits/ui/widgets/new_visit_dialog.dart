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
class NewVisitDialog extends StatelessWidget {
  /// Cria o dialog.
  const NewVisitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<VisitsController>();
    var title = '';
    return KortexScope(
      providers: [
        KortexProvider<KortexSignal<int?>>(create: (_) => kortexSignal<int?>(null)),
      ],
      child: Builder(
        builder: (context) {
          final clientIdSignal = context.readKortex<KortexSignal<int?>>();
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
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 12),
                    if (clients.isEmpty)
                      const Text('Cadastre um cliente antes de agendar.')
                    else
                      DropdownButtonFormField<int>(
                        key: const Key('new-visit-client'),
                        initialValue: clientIdSignal.value ?? clients.first.id,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: [
                          for (final client in clients)
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(client.name),
                            ),
                        ],
                        onChanged: (value) => clientIdSignal.value = value,
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
                onPressed: () =>
                    _save(context, controller, title, clientIdSignal.value),
                child: const Text('Agendar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    VisitsController controller,
    String title,
    int? clientId,
  ) async {
    final created = await controller.scheduleVisit(title, clientId: clientId);
    if (!created || !context.mounted) return;
    Navigator.of(context).pop();
  }
}
