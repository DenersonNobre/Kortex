/// Composition root do app de visitas.
///
/// SRP: montar o `KortexScope` ligando stores, fachadas e controllers.
/// NAO faz: regra de negocio nem UI.
///
/// Patterns: Scoped Service Locator (sempre via `BuildContext`).
/// Dependencias: Flutter + `kortex` + camadas `features` dos modulos.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../modules/clients/data/.index.dart';
import '../modules/clients/features/.index.dart';
import '../modules/session/.index.dart';
import '../modules/visits/data/.index.dart';
import '../modules/visits/features/.index.dart';
import '../modules/visits/ui/visits_controller.dart';
import 'app_shell.dart';

/// Monta o app de visitas com o escopo raiz.
///
/// [overrides] substitui providers do mesmo tipo (fakes em testes);
/// [seedDemo] cria o cliente de demonstracao no "banco" em memoria.
Widget createVisitsApp({
  List<KortexProvider<dynamic>> overrides = const [],
  bool seedDemo = true,
}) => KortexScope(
  overrides: overrides,
  providers: [
    KortexProvider<InMemoryClientStore>(
      create: (_) => InMemoryClientStore(seedDemo: seedDemo),
    ),
    KortexProvider<InMemoryVisitStore>(create: (_) => InMemoryVisitStore()),
    KortexProvider<ISessionProvider>(
      create: (_) => InMemorySessionProvider.demo(),
    ),
    KortexProvider<VisitUseCases>(
      create: (scope) => DefaultVisitUseCases(
        visits: scope.read<InMemoryVisitStore>(),
        clients: scope.read<InMemoryClientStore>(),
        session: scope.read<ISessionProvider>(),
      ),
    ),
    KortexProvider<ClientUseCases>(
      create: (scope) =>
          DefaultClientUseCases(clients: scope.read<InMemoryClientStore>()),
    ),
    KortexProvider<VisitsController>(
      create: (scope) => VisitsController(scope.read<VisitUseCases>())
        ..loadClients()
        ..refresh(),
    ),
  ],
  child: const MaterialApp(home: AppShell()),
);

/// Entrada do app de visitas.
void main() => runApp(createVisitsApp());
