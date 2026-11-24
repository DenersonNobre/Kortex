/// Pagina de visitas da POC (`StatelessWidget`).
///
/// SRP: compor filtro de status, lista e acoes, reagindo ao controller.
/// NAO faz: estado de negocio (papel do controller).
///
/// Patterns: `IKortexPage` + `KortexWatch` + `KortexListener` (erro).
/// Dependencias: Flutter + `kortex`.
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../core/ui/error_snackbar_listener.dart';
import '../features/.index.dart';
import 'visits_controller.dart';
import 'widgets/new_visit_dialog.dart';
import 'widgets/visits_list.dart';

/// Tela principal do app de visitas.
class VisitsPage extends IKortexPage<VisitsController> {
  /// Cria a pagina de visitas.
  const VisitsPage({super.key});

  @override
  Widget buildPage(BuildContext context, VisitsController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas técnicas'),
        actions: [
          IconButton(
            key: const Key('visits-refresh'),
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('visits-new'),
        tooltip: 'Nova visita',
        onPressed: () => showNewVisitDialog(context),
        child: const Icon(Icons.add),
      ),
      body: KortexErrorSnackBarListener(
        error: controller.error,
        child: Column(
          // Stretch: os filhos ocupam a largura toda, independentemente do
          // estado do corpo (sem isso a linha de filtros centraliza enquanto
          // carrega e "salta" para a esquerda quando os dados chegam).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusFilter(controller: controller),
            Expanded(child: _VisitsBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Corpo com os tres estados de `IKortexAsyncState`.
class _VisitsBody extends StatelessWidget {
  const _VisitsBody({required this.controller});

  final VisitsController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final state = controller.visits.state.value;
        return switch (state) {
          KortexAsyncLoading<List<VisitRow>>() => const Center(
            child: CircularProgressIndicator(),
          ),
          KortexAsyncError<List<VisitRow>>() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Falha ao carregar as visitas'),
                TextButton(
                  key: const Key('visits-retry'),
                  onPressed: controller.refresh,
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
          KortexAsyncData<List<VisitRow>>() => VisitsList(
            controller: controller,
          ),
        };
      },
    );
  }
}

/// Filtro por status da visita.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.controller});

  final VisitsController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, child) {
        final active = controller.statusFilter.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('visits-filter-${option.wire}'),
                    label: Text(option.label),
                    selected: active == option.wire,
                    // Sem checkmark o chip selecionado mantem a largura,
                    // evitando o reflow que desloca a linha ao filtrar.
                    showCheckmark: false,
                    onSelected: (_) =>
                        controller.applyStatusFilter(option.wire),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static const _options = [
    (wire: '', label: 'Todas'),
    (wire: 'scheduled', label: 'Agendadas'),
    (wire: 'in_progress', label: 'Em andamento'),
    (wire: 'completed', label: 'Concluídas'),
  ];
}
