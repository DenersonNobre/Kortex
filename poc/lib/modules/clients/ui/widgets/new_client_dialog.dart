/// Dialog de cadastro de cliente (escopo capturado no `Overlay`).
///
/// SRP: coletar nome e telefone e delegar ao controller.
/// NAO faz: regra de negocio nem lista.
///
/// Patterns: formulario com `KortexScope.capture`.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../clients_controller.dart';

/// Abre o dialog de novo cliente herdando o escopo da tela.
Future<void> showNewClientDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        KortexScope.capture(context: context, child: const NewClientDialog()),
  );
}

/// Formulario de novo cliente.
class NewClientDialog extends StatefulWidget {
  /// Cria o dialog.
  const NewClientDialog({super.key});

  @override
  State<NewClientDialog> createState() => _NewClientDialogState();
}

class _NewClientDialogState extends State<NewClientDialog> {
  var _name = '';
  var _phone = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<ClientsController>();
    return AlertDialog(
      title: const Text('Novo cliente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('client-name'),
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (value) => _name = value,
          ),
          TextFormField(
            key: const Key('client-phone'),
            decoration: const InputDecoration(labelText: 'Telefone'),
            onChanged: (value) => _phone = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('client-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('client-save'),
          onPressed: () => _save(controller),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _save(ClientsController controller) async {
    final created = await controller.createClient(_name, _phone);
    if (!created) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
