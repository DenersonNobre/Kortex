import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poc/app/tasks_app.dart';
import 'package:poc/modules/tasks/data/.index.dart';
import 'package:poc/modules/tasks/features/tasks_features.dart';
import 'package:poc/modules/tasks/ui/tasks_controller.dart';

/// Texto do `SnackBar` de erro que contem [pattern].
///
/// `find.text` exige match exato e o `InputDecoration` label repetiria a
/// palavra — por isso busca o descendant dentro do proprio `SnackBar`.
Finder _snackBarWith(Pattern pattern) => find.descendant(
  of: find.byType(SnackBar),
  matching: find.textContaining(pattern),
);

void main() {
  group('TasksPage', () {
    testWidgets('adiciona task pelo formulário', (tester) async {
      await tester.pumpWidget(createTasksApp());

      expect(find.text('Nenhuma task'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('task-title')), 'Ler');
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();

      expect(find.text('Ler'), findsOneWidget);
      expect(find.text('Nenhuma task'), findsNothing);
    });

    testWidgets('título vazio mostra erro e não persiste', (tester) async {
      await tester.pumpWidget(createTasksApp());

      await tester.enterText(find.byKey(const Key('task-title')), '   ');
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_snackBarWith('Título'), findsOneWidget);
      expect(find.text('Nenhuma task'), findsOneWidget);
    });

    testWidgets('conclui e remove a task', (tester) async {
      await tester.pumpWidget(createTasksApp());

      await tester.enterText(find.byKey(const Key('task-title')), 'Ler');
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();
      expect(find.text('Ler'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task-toggle-1')));
      await tester.pump();
      expect(find.text('Ler'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task-remove-1')));
      await tester.pump();
      expect(find.text('Nenhuma task'), findsOneWidget);
    });

    testWidgets('filtra por categoria', (tester) async {
      await tester.pumpWidget(createTasksApp());

      await tester.tap(find.byKey(const Key('category-add')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('category-name')), 'Casa');
      await tester.enterText(
        find.byKey(const Key('category-color')),
        '#ff0000',
      );
      await tester.tap(find.byKey(const Key('category-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('task-title')), 'Lavar');
      await tester.ensureVisible(find.byKey(const Key('task-category')));
      await tester.tap(find.byKey(const Key('task-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Casa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('task-title')), 'Estudar');
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();
      expect(find.text('Estudar'), findsOneWidget);
      expect(find.text('Lavar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('category-filter-1')));
      await tester.pump();

      expect(find.text('Estudar'), findsNothing);
      expect(find.text('Lavar'), findsOneWidget);
    });

    testWidgets('excluir categoria em uso mostra erro', (tester) async {
      await tester.pumpWidget(createTasksApp());

      await tester.tap(find.byKey(const Key('category-add')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('category-name')), 'Casa');
      await tester.enterText(
        find.byKey(const Key('category-color')),
        '#ff0000',
      );
      await tester.tap(find.byKey(const Key('category-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('task-title')), 'Lavar');
      await tester.ensureVisible(find.byKey(const Key('task-category')));
      await tester.tap(find.byKey(const Key('task-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Casa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-save')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('category-remove-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_snackBarWith('Categoria'), findsOneWidget);
      expect(find.text('Lavar'), findsOneWidget);
    });
  });

  group('TasksController', () {
    test('expõe lista vazia antes de carregar', () {
      final controller = TasksController(
        DefaultTaskUseCases(tasks: TaskStore(), categories: CategoryStore()),
      );

      expect(controller.tasks.value, isEmpty);
      expect(controller.error.value, isEmpty);
      controller.dispose();
    });
  });
}
