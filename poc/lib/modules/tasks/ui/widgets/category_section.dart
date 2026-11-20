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
class CategorySection extends StatefulWidget {
  /// Cria a secao ligada ao [controller].
  const CategorySection({super.key, required this.controller});

  /// Controller dono da secao.
  final TasksController controller;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('category-name'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('category-color'),
            controller: _colorController,
            decoration: const InputDecoration(labelText: 'Cor (#RRGGBB)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('category-save'),
            onPressed: () => _save(controller),
            child: const Text('Salvar categoria'),
          ),
        ],
      ),
    );
  }

  void _save(TasksController controller) {
    final created = controller.createCategory(
      _nameController.text,
      _colorController.text,
    );
    if (!created) return;
    _formKey.currentState?.reset();
    _nameController.clear();
    _colorController.clear();
    controller.toggleCategoryForm();
  }
}
