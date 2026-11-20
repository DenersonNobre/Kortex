/// Tecnico responsavel pela visita (`Technician`).
///
/// SRP: identificar o responsavel com nome e especialidade validos.
/// NAO faz: agenda, persistencia ou UI.
///
/// Patterns: Entidade imutavel + fabrica que devolve `Result`.
/// Dependencias: `core/result.dart` + codigos (puro).
library;

import '../../../core/result.dart';
import 'visit_failures.dart';

/// Tecnico sempre valido (construcao so via `create`).
final class Technician {
  const Technician._({
    required this.id,
    required this.name,
    required this.specialty,
  });

  /// Identificador (`0` antes da primeira persistencia).
  final int id;

  /// Nome do tecnico.
  final String name;

  /// Especialidade (rede, software, ...).
  final String specialty;

  /// Devolve copia com o [id] aplicado (persistência).
  Technician withId(int id) =>
      Technician._(id: id, name: name, specialty: specialty);

  /// Valida os campos e devolve `Ok` ou `Fail` com codigo estavel.
  static Result<Technician> create({
    required String name,
    required String specialty,
  }) {
    final trimmedName = name.trim();
    final trimmedSpecialty = specialty.trim();
    if (trimmedSpecialty.isEmpty) {
      return const Fail(
        VisitFailureCodes.technicianSpecialtyEmpty,
        'Tecnico sem especialidade.',
      );
    }
    return Ok(
      Technician._(id: 0, name: trimmedName, specialty: trimmedSpecialty),
    );
  }
}
