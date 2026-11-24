/// Composition root da POC de tasks.
///
/// SRP: montar o `KortexScope` ligando stores, fachada de casos de uso e
/// controller. NAO faz: regra de negocio nem UI.
///
/// Patterns: Scoped Service Locator (sempre via `BuildContext`).
/// Dependencias: Flutter + `kortex` + camada `features` da POC.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../modules/tasks/data/.index.dart';
import '../modules/tasks/features/tasks_features.dart';
import '../modules/tasks/ui/tasks_controller.dart';
import '../modules/tasks/ui/tasks_page.dart';

/// Monta o app da POC com o escopo raiz.
Widget createTasksApp() => KortexScope(
  providers: [
    KortexProvider<CategoryStore>(create: (_) => CategoryStore()),
    KortexProvider<TaskStore>(create: (_) => TaskStore()),
    KortexProvider<ITaskUseCases>(
      create: (scope) => DefaultTaskUseCases(
        tasks: scope.read<TaskStore>(),
        categories: scope.read<CategoryStore>(),
      ),
    ),
    KortexProvider<TasksController>(
      create: (scope) => TasksController(scope.read<ITaskUseCases>())
        ..refreshCategories()
        ..refresh(),
    ),
  ],
  child: const MaterialApp(home: TasksPage()),
);

/// Entrada do app da POC.
void main() => runApp(createTasksApp());
