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
class TaskForm extends StatelessWidget {
  /// Cria o formulario ligado ao [controller].
  const TaskForm({super.key, required this.controller});

  /// Controller que recebe o rascunho.
  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
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
            onPressed: () => _save(formContext, controller),
            child: const Text('Salvar'),
          ),
        ],
      ),
      ),
    );
  }

  void _save(BuildContext formContext, TasksController controller) {
    final created = controller.createTask();
    if (!created) return;
    Form.of(formContext).reset();
    controller.draft.clear();
  }
}
