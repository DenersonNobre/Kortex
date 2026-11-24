/// Pagina de tasks da POC (`StatelessWidget`).
///
/// SRP: compor o formulario, o filtro de categorias e a lista, reagindo ao
/// estado do controller. NAO faz: estado de negocio (papel do controller).
///
/// Patterns: `IKortexPage` (controller via escopo) + `KortexListener` (erro).
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../core/ui/error_snackbar_listener.dart';
import 'tasks_controller.dart';
import 'widgets/category_section.dart';
import 'widgets/task_form.dart';
import 'widgets/task_list.dart';

/// Tela unica da POC de tasks.
class TasksPage extends IKortexPage<TasksController> {
  /// Cria a pagina de tasks.
  const TasksPage({super.key});

  @override
  Widget buildPage(BuildContext context, TasksController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kortex POC — Tasks')),
      body: KortexErrorSnackBarListener(
        error: controller.error,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TaskForm(controller: controller),
            const SizedBox(height: 16),
            CategorySection(controller: controller),
            const SizedBox(height: 16),
            TaskList(controller: controller),
          ],
        ),
      ),
    );
  }
}
