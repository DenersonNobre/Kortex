/// Provedor de sessao em memoria (POC).
///
/// SRP: entregar o usuario corrente ao resto do app. NAO faz: autenticar,
/// autorizar nem persistir — em producao a identidade vem do servidor.
///
/// Patterns: Adapter da porta `ISessionProvider`.
/// Dependencias: dominio da sessao + `core/result.dart`.
library;

import '../../../core/result.dart';
import '../session.dart';

/// Sessao fixa em memoria: o tecnico logado e' o usuario do app.
class InMemorySessionProvider implements ISessionProvider {
  /// Cria a sessao com [currentUser] (injetavel nos testes).
  const InMemorySessionProvider({required this.currentUser});

  @override
  final SessionUser currentUser;

  /// Sessao de demonstracao usada no primeiro run da POC.
  factory InMemorySessionProvider.demo() {
    final user = SessionUser.create(name: 'Tecnico Demo', specialty: 'Rede');
    if (user is Ok<SessionUser>) {
      return InMemorySessionProvider(currentUser: user.value);
    }
    throw StateError('Usuario de demonstracao invalido.');
  }
}
