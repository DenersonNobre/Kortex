/// Secao de categorias da POC (filtro, cadastro e exclusao).
///
/// SRP: filtrar a lista por categoria e gerenciar o cadastro de categorias.
/// NAO faz: criar task nem persistir direto.
///
/// Patterns: `KortexWatch` (rebuild granular) + rascunho local.
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../tasks_controller.dart';

/// Filtro de categoria, cadastro e remocao.
class CategorySection extends StatelessWidget {
  /// Cria a secao ligada ao [controller].
  const CategorySection({super.key, required this.controller});

  /// Controller dono da secao.
  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final categories = controller.categories.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Todas'),
                  onPressed: () => controller.applyFilter(null),
                ),
                for (final category in categories)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputChip(
                        key: Key('category-filter-${category.id}'),
                        label: Text(category.name.value),
                        selected: controller.filter.value == category.id,
                        onSelected: (_) => controller.applyFilter(category.id),
                      ),
                      IconButton(
                        key: Key('category-remove-${category.id}'),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => controller.removeCategory(category.id),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('category-add'),
              onPressed: controller.toggleCategoryForm,
              child: const Text('Nova categoria'),
            ),
            if (controller.showCategoryForm.value) _buildForm(controller),
          ],
        );
      },
    );
  }

  Widget _buildForm(TasksController controller) {
    var name = '';
    var color = '';
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('category-name'),
              decoration: const InputDecoration(labelText: 'Nome'),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('category-color'),
              decoration: const InputDecoration(labelText: 'Cor (#RRGGBB)'),
              onChanged: (value) => color = value,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('category-save'),
              onPressed: () {
                final created = controller.createCategory(name, color);
                if (!created) return;
                Form.of(formContext).reset();
                controller.toggleCategoryForm();
              },
              child: const Text('Salvar categoria'),
            ),
          ],
        ),
      ),
    );
  }
}
