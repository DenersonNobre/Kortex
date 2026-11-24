import 'package:poc/core/result.dart';

import '../support/fixtures.dart';

import 'package:poc/modules/visits/domain/checklist_item.dart';
import 'package:poc/modules/visits/domain/visit.dart';
import 'package:poc/modules/visits/domain/visit_failures.dart';
import 'package:poc/modules/visits/domain/visit_status.dart';
import 'package:poc/modules/visits/domain/visit_title.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(AppResult<T> result) {
  expect(result, isA<Success<T, AppFailure>>());
  return (result as Success<T, AppFailure>).value;
}

void main() {
  group('VisitTitle (VO)', () {
    test('vazio reprova com VISIT_TITLE_EMPTY', () {
      final result = VisitTitle.create('   ');

      expect(result, isA<Failure<VisitTitle, AppFailure>>());
      expect(
        (result as Failure<dynamic, AppFailure>).code,
        VisitFailureCodes.titleEmpty,
      );
    });

    test('acima de 140 caracteres reprova com VISIT_TITLE_TOO_LONG', () {
      final result = VisitTitle.create('x' * 141);

      expect(result, isA<Failure<VisitTitle, AppFailure>>());
      expect(
        (result as Failure<dynamic, AppFailure>).code,
        VisitFailureCodes.titleTooLong,
      );
    });

    test('valido normaliza e aprova', () {
      final title = _ok(VisitTitle.create('  Troca do roteador  '));

      expect(title.value, 'Troca do roteador');
    });
  });

  group('EVisitStatus', () {
    test('parse valido devolve o status', () {
      final status = EVisitStatus.parse('scheduled');

      expect(status, isA<Success<EVisitStatus, AppFailure>>());
      expect(
        (status as Success<EVisitStatus, AppFailure>).value,
        EVisitStatus.scheduled,
      );
    });

    test('status invalido reprova com VISIT_STATUS_INVALID', () {
      final status = EVisitStatus.parse('concluida');

      expect(status, isA<Failure<EVisitStatus, AppFailure>>());
      expect(
        (status as Failure<dynamic, AppFailure>).code,
        VisitFailureCodes.statusInvalid,
      );
    });

    test('transicoes de status sao validas', () {
      expect(EVisitStatus.scheduled.canStart, isTrue);
      expect(EVisitStatus.scheduled.canComplete, isFalse);
      expect(EVisitStatus.inProgress.canStart, isFalse);
      expect(EVisitStatus.inProgress.canComplete, isTrue);
      expect(EVisitStatus.completed.canStart, isFalse);
      expect(EVisitStatus.completed.canComplete, isFalse);
    });
  });

  group('ChecklistItem', () {
    test('descricao vazia reprova com CHECKLIST_DESCRIPTION_EMPTY', () {
      final item = ChecklistItem.create(description: '  ');

      expect(item, isA<Failure<ChecklistItem, AppFailure>>());
      expect(
        (item as Failure<dynamic, AppFailure>).code,
        VisitFailureCodes.checklistDescriptionEmpty,
      );
    });

    test('valido comeca nao concluido', () {
      final item = _ok(ChecklistItem.create(description: ' Testar sinal '));

      expect(item.description, 'Testar sinal');
      expect(item.done, isFalse);
    });
  });

  group('Visit (agregado raiz)', () {
    test('draft valida titulo e itens de checklist', () {
      final draft = Visit.draft(
        scheduledAt: at(21),
        title: 'Troca do roteador',
        clientId: 1,
        technicianName: 'Ana',
        checklist: [_ok(ChecklistItem.create(description: 'Testar sinal'))],
      );

      expect(draft, isA<Success<Visit, AppFailure>>());
      final visit = (draft as Success<Visit, AppFailure>).value;
      expect(visit.id, 0);
      expect(visit.status, EVisitStatus.scheduled);
      expect(visit.checklist, hasLength(1));
    });

    test('draft com titulo vazio reprova sem criar visita', () {
      final draft = Visit.draft(
        scheduledAt: at(21),
        title: '  ',
        clientId: 1,
        technicianName: 'Ana',
      );

      expect(draft, isA<Failure<Visit, AppFailure>>());
      expect(
        (draft as Failure<dynamic, AppFailure>).code,
        VisitFailureCodes.titleEmpty,
      );
    });

    test('concluir checklist marca todos os itens', () {
      final visit = _ok(
        Visit.draft(
          scheduledAt: at(21),
          title: 'Troca',
          clientId: 1,
          technicianName: 'Ana',
          checklist: [
            _ok(ChecklistItem.create(description: 'A')),
            _ok(ChecklistItem.create(description: 'B')),
          ],
        ),
      );

      final completed = visit.completeChecklist();

      expect(completed.checklist.every((item) => item.done), isTrue);
      expect(visit.checklist.every((item) => item.done), isFalse);
    });

    test('progresso e a razao de itens concluidos', () {
      final visit = _ok(
        Visit.draft(
          scheduledAt: at(21),
          title: 'Troca',
          clientId: 1,
          technicianName: 'Ana',
          checklist: [
            _ok(ChecklistItem.create(description: 'A')),
            _ok(ChecklistItem.create(description: 'B')),
          ],
        ),
      );

      expect(visit.progress, 0);

      final withOne = visit.toggleChecklist(0);
      expect(withOne.progress, 0.5);
      expect(withOne.checklist.first.done, isTrue);
    });

    test('toggle de item inexistente mantem a visita intacta', () {
      final visit = _ok(
        Visit.draft(
          scheduledAt: at(21),
          title: 'Troca',
          clientId: 1,
          technicianName: 'Ana',
          checklist: [_ok(ChecklistItem.create(description: 'A'))],
        ),
      );

      final toggled = visit.toggleChecklist(9);

      expect(toggled.checklist.first.done, isFalse);
    });
  });
}
