/// Formulario de criacao de task da POC.
///
/// SRP: coletar o rascunho (titulo + categoria) e delegar ao controller.
/// NAO faz: regra de negocio nem leitura de estado da lista.
///
/// Patterns: rascunho mutavel (sem `TextEditingController`) + `Form` com reset.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../tasks_controller.dart';

/// Formulario de criacao de task.
class TaskForm extends StatefulWidget {
  /// Cria o formulario ligado ao [controller].
  const TaskForm({super.key, required this.controller});

  /// Controller que recebe o rascunho.
  final TasksController controller;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('task-title'),
            initialValue: '',
            decoration: const InputDecoration(labelText: 'Título'),
            onChanged: (value) => controller.draft.title = value,
          ),
          const SizedBox(height: 8),
          KortexWatch(
            builder: (context, child) {
              final categories = controller.categories.value;
              return DropdownButtonFormField<int?>(
                key: const Key('task-category'),
                initialValue: controller.draft.categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sem categoria'),
                  ),
                  for (final category in categories)
                    DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name.value),
                    ),
                ],
                onChanged: (value) => controller.draft.categoryId = value,
              );
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('task-save'),
            onPressed: () => _save(controller),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _save(TasksController controller) {
    final created = controller.createTask();
    if (!created) return;
    _formKey.currentState?.reset();
    controller.draft.clear();
  }
}
