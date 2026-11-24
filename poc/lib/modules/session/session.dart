/// Usuario da sessao (`SessionUser`).
///
/// SRP: representar quem esta usando o app. NAO faz: autenticacao, papeis
/// nem persistencia — na POC o tecnico e' o proprio usuario (identidade em
/// memoria); em producao viria do servidor.
///
/// Patterns: Value Object imutavel + porta de leitura da sessao.
/// Dependencias: `core/result.dart` (puro).
library;

import '../../../core/result.dart';
import 'session_failures.dart';

/// Usuario sempre valido (construcao so via `create`).
final class SessionUser {
  const SessionUser._({required this.name, required this.specialty});

  /// Nome do tecnico logado.
  final String name;

  /// Especialidade (rede, software, ...).
  final String specialty;

  /// Valida os campos e devolve `Ok` ou `Fail` com codigo estavel.
  static IResult<SessionUser> create({
    required String name,
    required String specialty,
  }) {
    final trimmedName = name.trim();
    final trimmedSpecialty = specialty.trim();
    if (trimmedName.isEmpty) {
      return const Fail(SessionFailureCodes.nameEmpty, 'Usuario sem nome.');
    }
    if (trimmedSpecialty.isEmpty) {
      return const Fail(
        SessionFailureCodes.specialtyEmpty,
        'Usuario sem especialidade.',
      );
    }
    return Ok(SessionUser._(name: trimmedName, specialty: trimmedSpecialty));
  }
}

/// Porta de leitura do usuario atual (injetada pelo composition root).
abstract interface class ISessionProvider {
  /// Usuario da sessao corrente.
  SessionUser get currentUser;
}
