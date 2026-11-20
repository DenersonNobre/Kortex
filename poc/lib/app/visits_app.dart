/// Composition root do app de visitas.
///
/// SRP: montar o `KortexScope` ligando stores, fachada e controller.
/// NAO faz: regra de negocio nem UI.
///
/// Patterns: Scoped Service Locator (sempre via `BuildContext`).
/// Dependencias: Flutter + `kortex` + camada `features` do modulo.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../modules/visits/data/.index.dart';
import '../modules/visits/features/.index.dart';
import '../modules/visits/ui/visits_controller.dart';
import '../modules/visits/ui/visits_page.dart';

/// Monta o app de visitas com o escopo raiz.
///
/// [overrides] substitui providers do mesmo tipo (fakes em testes);
/// [seedDemo] cria cliente/tecnico de demonstracao quando as listas vazias.
Widget createVisitsApp({
  List<KortexProvider<dynamic>> overrides = const [],
  bool seedDemo = true,
}) => KortexScope(
  overrides: overrides,
  providers: [
    KortexProvider<InMemoryClientStore>(create: (_) => InMemoryClientStore()),
    KortexProvider<InMemoryTechnicianStore>(
      create: (_) => InMemoryTechnicianStore(),
    ),
    KortexProvider<InMemoryVisitStore>(create: (_) => InMemoryVisitStore()),
    KortexProvider<VisitUseCases>(
      create: (scope) => DefaultVisitUseCases(
        visits: scope.read<InMemoryVisitStore>(),
        clients: scope.read<InMemoryClientStore>(),
        technicians: scope.read<InMemoryTechnicianStore>(),
      ),
    ),
    KortexProvider<VisitsController>(
      create: (scope) => VisitsController(scope.read<VisitUseCases>())
        ..loadFormData(seedIfEmpty: seedDemo)
        ..refresh(),
    ),
  ],
  child: const MaterialApp(home: VisitsPage()),
);

/// Entrada do app de visitas.
void main() => runApp(createVisitsApp());
