/// Lista de tasks da POC.
///
/// SRP: renderizar a lista reativa com acoes de concluir e remover.
/// NAO faz: criar task nem manter estado proprio.
///
/// Patterns: `KortexWatch` (rebuild granular) + `KortexSelector` (filtro).
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../features/queries/task_row.dart';
import '../tasks_controller.dart';

/// Lista de tasks com concluir e remover.
class TaskList extends StatelessWidget {
  /// Cria a lista ligada ao [controller].
  const TaskList({super.key, required this.controller});

  /// Controller dono da lista.
  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final tasks = controller.tasks.value;
        if (tasks.isEmpty) {
          return const Text('Nenhuma task');
        }
        return Column(
          children: [
            for (final task in tasks)
              _TaskRow(controller: controller, task: task),
          ],
        );
      },
    );
  }
}

/// Linha de uma task (concluir e remover).
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.controller, required this.task});

  final TasksController controller;
  final TaskRow task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        key: Key('task-toggle-${task.id}'),
        value: task.done,
        onChanged: (_) => controller.toggleTask(task.id),
      ),
      title: Text(task.title),
      subtitle: task.categoryName == null
          ? null
          : Text(task.categoryName!, textDirection: TextDirection.ltr),
      trailing: IconButton(
        key: Key('task-remove-${task.id}'),
        icon: const Icon(Icons.delete_outline),
        onPressed: () => controller.removeTask(task.id),
      ),
    );
  }
}
