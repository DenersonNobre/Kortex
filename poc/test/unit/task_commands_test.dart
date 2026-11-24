import 'package:poc/core/result.dart';
import 'package:poc/modules/tasks/data/.index.dart';
import 'package:poc/modules/tasks/domain/.index.dart';
import 'package:poc/modules/tasks/task_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta a fachada sobre stores em memória.
ITaskUseCases _useCases() =>
    DefaultTaskUseCases(tasks: TaskStore(), categories: CategoryStore());

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(IResult<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// Código de um `Fail` (falha o teste se for `Ok`).
String _code<T>(IResult<T> result) {
  expect(result, isA<Fail<T>>());
  return (result as Fail).code;
}

void main() {
  group('ITaskUseCases (tasks)', () {
    test('create válido persiste e lista', () {
      final useCases = _useCases();

      final created = _ok(useCases.create('Estudar'));

      expect(created.id, isNonZero);
      expect(useCases.listAll(), hasLength(1));
    });

    test('create vazio falha sem persistir', () {
      final useCases = _useCases();

      expect(_code(useCases.create('  ')), TaskFailureCodes.emptyTitle);
      expect(useCases.listAll(), isEmpty);
    });

    test('create com categoria inexistente falha', () {
      final useCases = _useCases();

      expect(
        _code(useCases.create('X', categoryId: 99)),
        CategoryFailureCodes.notFound,
      );
      expect(useCases.listAll(), isEmpty);
    });

    test('toggle inexistente falha e lista segue intacta', () {
      final useCases = _useCases();
      _ok(useCases.create('A'));

      expect(_code(useCases.toggle(99)), TaskFailureCodes.notFound);
      expect(useCases.listAll(), hasLength(1));
    });

    test('remove devolve a removida', () {
      final useCases = _useCases();
      final created = _ok(useCases.create('A'));

      final removed = _ok(useCases.remove(created.id));

      expect(removed.id, created.id);
      expect(useCases.listAll(), isEmpty);
      expect(_code(useCases.remove(created.id)), TaskFailureCodes.notFound);
    });
  });

  group('ITaskUseCases (categories)', () {
    test('createCategory valida nome e cor', () {
      final useCases = _useCases();

      expect(
        _code(useCases.createCategory('', '#ff0000')),
        CategoryFailureCodes.emptyName,
      );
      expect(
        _code(useCases.createCategory('Casa', 'vermelho')),
        CategoryFailureCodes.invalidColor,
      );
      expect(useCases.listCategories(), isEmpty);

      final category = _ok(useCases.createCategory('Casa', '#ff0000'));
      expect(category.id, isNonZero);
      expect(useCases.listCategories(), hasLength(1));
    });

    test('deleteCategory em uso falha e preserva tudo', () {
      final useCases = _useCases();
      final category = _ok(useCases.createCategory('Casa', '#00ff00'));
      _ok(useCases.create('Lavar', categoryId: category.id));

      expect(
        _code(useCases.deleteCategory(category.id)),
        CategoryFailureCodes.inUse,
      );
      expect(useCases.listCategories(), hasLength(1));
      expect(useCases.listAll(), hasLength(1));
    });

    test('deleteCategory livre remove e inexistente falha', () {
      final useCases = _useCases();
      final category = _ok(useCases.createCategory('Casa', '#00ff00'));

      final deleted = _ok(useCases.deleteCategory(category.id));

      expect(deleted.id, category.id);
      expect(useCases.listCategories(), isEmpty);
      expect(
        _code(useCases.deleteCategory(category.id)),
        CategoryFailureCodes.notFound,
      );
    });

    test('assign vincula, valida e desvincula com null', () {
      final useCases = _useCases();
      final task = _ok(useCases.create('Lavar'));
      final category = _ok(useCases.createCategory('Casa', '#0000ff'));

      expect(
        _code(useCases.assignCategory(99, category.id)),
        TaskFailureCodes.notFound,
      );
      expect(
        _code(useCases.assignCategory(task.id, 99)),
        CategoryFailureCodes.notFound,
      );

      final assigned = _ok(useCases.assignCategory(task.id, category.id));
      expect(assigned.categoryId, category.id);

      final cleared = _ok(useCases.assignCategory(task.id, null));
      expect(cleared.categoryId, isNull);
    });
  });

  group('ITaskUseCases (queries com join)', () {
    test('listByCategory filtra e view carrega o nome', () {
      final useCases = _useCases();
      final home = _ok(useCases.createCategory('Casa', '#00ff00'));
      final work = _ok(useCases.createCategory('Trabalho', '#0000ff'));
      _ok(useCases.create('Lavar', categoryId: home.id));
      _ok(useCases.create('Relatório', categoryId: work.id));
      _ok(useCases.create('Ler'));

      expect(useCases.listAll(), hasLength(3));

      final homeTasks = useCases.listByCategory(home.id);
      expect(homeTasks, hasLength(1));
      expect(homeTasks.single.categoryName, 'Casa');

      expect(useCases.listByCategory(null), hasLength(1));
    });
  });

  group('ITaskUseCases (integridade)', () {
    test('assign preserva título e done', () {
      final useCases = _useCases();
      final task = _ok(useCases.create('Lavar'));
      final category = _ok(useCases.createCategory('Casa', '#00ff00'));

      final assigned = _ok(useCases.assignCategory(task.id, category.id));

      expect(assigned.title.value, 'Lavar');
      expect(assigned.done, task.done);
      expect(assigned.categoryId, category.id);
    });
  });
}
