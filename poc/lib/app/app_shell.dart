/// Shell do app: barra de navegacao entre Visitas, Agenda e Clientes.
///
/// SRP: manter a area ativa e compor cada pagina no escopo correto.
/// NAO faz: regra de negocio, roteamento proprio nem estado de dominio.
///
/// Patterns: `NavigationBar` (Material 3) + `IndexedStack` (preserva estado).
/// Dependencias: Flutter + `kortex` + paginas do app.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../modules/clients/features/.index.dart';
import '../modules/clients/ui/clients_controller.dart';
import '../modules/clients/ui/clients_page.dart';
import '../modules/visits/features/.index.dart';
import '../modules/visits/ui/agenda_controller.dart';
import '../modules/visits/ui/agenda_page.dart';
import '../modules/visits/ui/visits_page.dart';

/// Shell com as tres areas do app.
class AppShell extends StatefulWidget {
  /// Cria o shell.
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const VisitsPage(),
          AgendaScope(child: const AgendaPage()),
          ClientsScope(child: const ClientsPage()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Visitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Clientes',
          ),
        ],
      ),
    );
  }
}

/// Escopo da agenda (subarvore propria, controller dedicado).
///
/// Providers criados **uma vez** (`didChangeDependencies`): recriar a lista a
/// cada build faria o `KortexScope` descartar e recriar o controller.
class AgendaScope extends StatefulWidget {
  /// Cria o escopo com o controller de agenda.
  const AgendaScope({super.key, required this.child});

  /// Subarvore que consome o controller.
  final Widget child;

  @override
  State<AgendaScope> createState() => _AgendaScopeState();
}

class _AgendaScopeState extends State<AgendaScope> {
  List<KortexProvider<dynamic>>? _providers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final useCases = context.readKortex<VisitUseCases>();
    _providers ??= [
      KortexProvider<AgendaController>(
        create: (_) => AgendaController(useCases)..refresh(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      KortexScope(providers: _providers!, child: widget.child);
}

/// Escopo dos clientes (subarvore propria, controller dedicado).
///
/// Providers criados **uma vez** (`didChangeDependencies`): recriar a lista a
/// cada build faria o `KortexScope` descartar e recriar o controller.
class ClientsScope extends StatefulWidget {
  /// Cria o escopo com o controller de clientes.
  const ClientsScope({super.key, required this.child});

  /// Subarvore que consome o controller.
  final Widget child;

  @override
  State<ClientsScope> createState() => _ClientsScopeState();
}

class _ClientsScopeState extends State<ClientsScope> {
  List<KortexProvider<dynamic>>? _providers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final useCases = context.readKortex<ClientUseCases>();
    _providers ??= [
      KortexProvider<ClientsController>(
        create: (_) => ClientsController(useCases)..refresh(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      KortexScope(providers: _providers!, child: widget.child);
}
