import 'package:poc/core/result.dart';
import 'package:poc/modules/tasks/data/.index.dart';
import 'package:poc/modules/tasks/domain/.index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

void main() {
  group('TaskTitle (VO)', () {
    test('vazio reprova com TASK_EMPTY_TITLE', () {
      final result = TaskTitle.create('   ');

      expect(result, isA<Fail<TaskTitle>>());
      expect((result as Fail).code, TaskFailureCodes.emptyTitle);
    });

    test('acima de 120 caracteres reprova com TASK_TITLE_TOO_LONG', () {
      final result = TaskTitle.create('x' * 121);

      expect(result, isA<Fail<TaskTitle>>());
      expect((result as Fail).code, TaskFailureCodes.titleTooLong);
    });

    test('válido normaliza (trim) e aprova', () {
      final title = _ok(TaskTitle.create('  Comprar leite  '));

      expect(title.value, 'Comprar leite');
    });
  });

  group('Task (entidade imutável)', () {
    test('draft valida e usa id 0 (transiente)', () {
      final created = _ok(Task.draft('Ler'));

      expect(created.id, 0);
      expect(created.done, isFalse);

      final invalid = Task.draft('  ');
      expect(invalid, isA<Fail<Task>>());
      expect((invalid as Fail).code, TaskFailureCodes.emptyTitle);
    });

    test('toggle inverte done sem mutar o original', () {
      final task = Task(id: 1, title: _ok(TaskTitle.create('A')));

      final toggled = task.toggle();

      expect(toggled.done, isTrue);
      expect(toggled.id, 1);
      expect(toggled.title.value, 'A');
      expect(task.done, isFalse);
    });
  });

  group('TaskStore', () {
    test('save atribui ids sequenciais', () {
      final repo = TaskStore();

      final first = repo.save(_ok(Task.draft('A')));
      final second = repo.save(_ok(Task.draft('B')));

      expect(first.id, 1);
      expect(second.id, 2);
    });

    test('findAll ordena por id e findById ausente é null', () {
      final repo = TaskStore();
      repo.save(_ok(Task.draft('B')));
      repo.save(_ok(Task.draft('A')));

      expect(repo.findAll().map((task) => task.id), [1, 2]);
      expect(repo.findById(99), isNull);
    });

    test('save com id substitui e deleteById remove', () {
      final repo = TaskStore();
      final created = repo.save(_ok(Task.draft('A')));

      repo.save(created.toggle());
      expect(repo.findById(created.id)?.done, isTrue);

      repo.deleteById(created.id);
      expect(repo.findById(created.id), isNull);
      expect(repo.findAll(), isEmpty);
    });
  });
}
