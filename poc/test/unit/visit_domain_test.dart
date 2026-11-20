import 'package:poc/core/result.dart';

import '../support/fixtures.dart';

import 'package:poc/modules/visits/domain/checklist_item.dart';
import 'package:poc/modules/visits/domain/client.dart';
import 'package:poc/modules/visits/domain/technician.dart';
import 'package:poc/modules/visits/domain/visit.dart';
import 'package:poc/modules/visits/domain/visit_failures.dart';
import 'package:poc/modules/visits/domain/visit_status.dart';
import 'package:poc/modules/visits/domain/visit_title.dart';
import 'package:flutter_test/flutter_test.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

void main() {
  group('VisitTitle (VO)', () {
    test('vazio reprova com VISIT_TITLE_EMPTY', () {
      final result = VisitTitle.create('   ');

      expect(result, isA<Fail<VisitTitle>>());
      expect((result as Fail).code, VisitFailureCodes.titleEmpty);
    });

    test('acima de 140 caracteres reprova com VISIT_TITLE_TOO_LONG', () {
      final result = VisitTitle.create('x' * 141);

      expect(result, isA<Fail<VisitTitle>>());
      expect((result as Fail).code, VisitFailureCodes.titleTooLong);
    });

    test('valido normaliza e aprova', () {
      final title = _ok(VisitTitle.create('  Troca do roteador  '));

      expect(title.value, 'Troca do roteador');
    });
  });

  group('VisitStatus', () {
    test('parse valido devolve o status', () {
      final status = VisitStatus.parse('scheduled');

      expect(status, isA<Ok<VisitStatus>>());
      expect((status as Ok<VisitStatus>).value, VisitStatus.scheduled);
    });

    test('status invalido reprova com VISIT_STATUS_INVALID', () {
      final status = VisitStatus.parse('concluida');

      expect(status, isA<Fail<VisitStatus>>());
      expect((status as Fail).code, VisitFailureCodes.statusInvalid);
    });

    test('transicoes de status sao validas', () {
      expect(VisitStatus.scheduled.canStart, isTrue);
      expect(VisitStatus.scheduled.canComplete, isFalse);
      expect(VisitStatus.inProgress.canStart, isFalse);
      expect(VisitStatus.inProgress.canComplete, isTrue);
      expect(VisitStatus.completed.canStart, isFalse);
      expect(VisitStatus.completed.canComplete, isFalse);
    });
  });

  group('ChecklistItem', () {
    test('descricao vazia reprova com CHECKLIST_DESCRIPTION_EMPTY', () {
      final item = ChecklistItem.create(description: '  ');

      expect(item, isA<Fail<ChecklistItem>>());
      expect((item as Fail).code, VisitFailureCodes.checklistDescriptionEmpty);
    });

    test('valido comeca nao concluido', () {
      final item = _ok(ChecklistItem.create(description: ' Testar sinal '));

      expect(item.description, 'Testar sinal');
      expect(item.done, isFalse);
    });
  });

  group('Client', () {
    test('telefone invalido reprova com CLIENT_PHONE_INVALID', () {
      final client = Client.create(name: 'Cliente', phone: '123');

      expect(client, isA<Fail<Client>>());
      expect((client as Fail).code, VisitFailureCodes.clientPhoneInvalid);
    });

    test('valido aprova com id transiente', () {
      final client = _ok(
        Client.create(name: 'Cliente', phone: '(11) 98888-7777'),
      );

      expect(client.id, 0);
      expect(client.name, 'Cliente');
    });
  });

  group('Technician', () {
    test('especialidade vazia reprova com TECHNICIAN_SPECIALTY_EMPTY', () {
      final technician = Technician.create(name: 'Ana', specialty: '  ');

      expect(technician, isA<Fail<Technician>>());
      expect(
        (technician as Fail).code,
        VisitFailureCodes.technicianSpecialtyEmpty,
      );
    });

    test('valido aprova', () {
      final technician = _ok(Technician.create(name: 'Ana', specialty: 'Rede'));

      expect(technician.name, 'Ana');
      expect(technician.specialty, 'Rede');
    });
  });

  group('Visit (agregado raiz)', () {
    test('draft valida titulo e itens de checklist', () {
      final draft = Visit.draft(
        scheduledAt: at(21),
        title: 'Troca do roteador',
        clientId: 1,
        technicianId: 2,
        checklist: [_ok(ChecklistItem.create(description: 'Testar sinal'))],
      );

      expect(draft, isA<Ok<Visit>>());
      final visit = (draft as Ok<Visit>).value;
      expect(visit.id, 0);
      expect(visit.status, VisitStatus.scheduled);
      expect(visit.checklist, hasLength(1));
    });

    test('draft com titulo vazio reprova sem criar visita', () {
      final draft = Visit.draft(
        scheduledAt: at(21),
        title: '  ',
        clientId: 1,
        technicianId: 2,
      );

      expect(draft, isA<Fail<Visit>>());
      expect((draft as Fail).code, VisitFailureCodes.titleEmpty);
    });

    test('concluir checklist marca todos os itens', () {
      final visit = _ok(
        Visit.draft(
          scheduledAt: at(21),
          title: 'Troca',
          clientId: 1,
          technicianId: 2,
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
          technicianId: 2,
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
          technicianId: 2,
          checklist: [_ok(ChecklistItem.create(description: 'A'))],
        ),
      );

      final toggled = visit.toggleChecklist(9);

      expect(toggled.checklist.first.done, isFalse);
    });
  });
}
