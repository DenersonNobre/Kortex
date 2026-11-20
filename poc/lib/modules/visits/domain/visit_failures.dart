/// Codigos estaveis de falha do modulo de visitas.
///
/// SRP: centralizar os `code`s de `Fail` do dominio. NAO faz: mensagens
/// (vao no `Fail.message` de cada sitio).
library;

/// Codigos de falha de negocio das visitas.
abstract final class VisitFailureCodes {
  /// Titulo da visita vazio ou so espacos.
  static const titleEmpty = 'VISIT_TITLE_EMPTY';

  /// Titulo acima de `VisitTitle.maxLength`.
  static const titleTooLong = 'VISIT_TITLE_TOO_LONG';

  /// Status de visita desconhecido.
  static const statusInvalid = 'VISIT_STATUS_INVALID';

  /// Descricao de item de checklist vazia.
  static const checklistDescriptionEmpty = 'CHECKLIST_DESCRIPTION_EMPTY';

  /// Telefone do cliente invalido.
  static const clientPhoneInvalid = 'CLIENT_PHONE_INVALID';

  /// Especialidade do tecnico vazia.
  static const technicianSpecialtyEmpty = 'TECHNICIAN_SPECIALTY_EMPTY';

  /// Cliente inexistente.
  static const clientNotFound = 'CLIENT_NOT_FOUND';

  /// Tecnico inexistente.
  static const technicianNotFound = 'TECHNICIAN_NOT_FOUND';

  /// Visita inexistente.
  static const visitNotFound = 'VISIT_NOT_FOUND';

  /// Visita ja iniciada.
  static const visitAlreadyStarted = 'VISIT_ALREADY_STARTED';

  /// Visita que nao esta em andamento.
  static const visitNotInProgress = 'VISIT_NOT_IN_PROGRESS';

  /// Data/hora agendada no passado (ou ausente).
  static const scheduledInPast = 'VISIT_IN_PAST';
}
