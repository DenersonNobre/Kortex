/// Controller reativo do app de visitas.
///
/// SRP: expor a lista de visitas (assincrona, com `previousValue` e
/// `KortexAsyncState`), o filtro por status e as acoes do ciclo da visita.
/// NAO faz: UI, navegacao nem regra de negocio (vive nos commands).
///
/// Patterns: `IKortexController` + `KortexResource` (carga concorrente) e
/// `KortexCommand` (trava de duplo clique nas acoes).
/// Dependencias: `kortex` + camada `features` do modulo de visitas.
library;

import 'package:kortex/kortex.dart';

import '../../../core/result.dart';
import '../domain/.index.dart';
import '../features/list_visits/visit_row.dart';
import '../features/visit_use_cases.dart';

/// Controller da lista e das acoes de visita.
class VisitsController extends IKortexController {
  /// Registra resource, sinais e commands no `disposeBag`.
  VisitsController(this._useCases) {
    visits = autoDispose(
      kortexResource<List<VisitRow>>(
        () =>
            _useCases.listVisits(status: _statusFromWire(statusFilter.peek())),
        immediate: false,
      ),
    );
    startCommand = autoDispose(
      kortexCommand<int, Result<Visit>>(_useCases.startVisit),
    );
    autoDispose(statusFilter);
    autoDispose(error);
    autoDispose(showNewVisitDialog);
  }

  final VisitUseCases _useCases;

  /// Lista de visitas com cliente, tecnico e progresso.
  late final KortexResource<List<VisitRow>> visits;

  /// Comando de inicio de visita (trava de duplo clique).
  late final KortexCommand<int, Result<Visit>> startCommand;

  /// Status ativo do filtro (`''` = todos).
  final KortexSignal<String> statusFilter = KortexSignal('');

  /// Mensagem de erro da ultima acao.
  final KortexSignal<String> error = KortexSignal('');

  /// Exibe o dialog de nova visita.
  final KortexSignal<bool> showNewVisitDialog = KortexSignal(false);

  /// Clientes cadastrados (para o formulario).
  final KortexSignal<List<Client>> clients = KortexSignal(const []);

  /// Tecnicos cadastrados (para o formulario).
  final KortexSignal<List<Technician>> technicians = KortexSignal(const []);

  /// Recarrega a lista de visitas.
  Future<void> refresh() => visits.refresh();

  /// Recarrega clientes e tecnicos do formulario.
  ///
  /// Com [seedIfEmpty], cria um cliente e um tecnico de demonstracao quando
  /// as listas estao vazias — deixa a POC utilizavel no primeiro `flutter run`.
  Future<void> loadFormData({bool seedIfEmpty = false}) async {
    try {
      var clientList = await _useCases.listClients();
      var technicianList = await _useCases.listTechnicians();
      if (seedIfEmpty && clientList.isEmpty) {
        await _useCases.createClient(
          name: 'Cliente Demo',
          phone: '11988887777',
        );
        clientList = await _useCases.listClients();
      }
      if (seedIfEmpty && technicianList.isEmpty) {
        await _useCases.createTechnician(
          name: 'Tecnico Demo',
          specialty: 'Rede',
        );
        technicianList = await _useCases.listTechnicians();
      }
      clients.value = clientList;
      technicians.value = technicianList;
    } catch (_) {
      // A lista principal ja' publica o erro de infraestrutura em
      // `visits.state` (KortexAsyncError); o formulario nao duplica o aviso.
    }
  }

  /// Aplica o filtro de status e recarrega.
  Future<void> applyStatusFilter(String wire) async {
    statusFilter.value = wire;
    await refresh();
  }

  /// Cadastra cliente; devolve `true` em caso de sucesso.
  Future<bool> createClient(String name, String phone) async {
    final result = await _useCases.createClient(name: name, phone: phone);
    if (result is Fail<Client>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await loadFormData();
    return true;
  }

  /// Cadastra tecnico; devolve `true` em caso de sucesso.
  Future<bool> createTechnician(String name, String specialty) async {
    final result = await _useCases.createTechnician(
      name: name,
      specialty: specialty,
    );
    if (result is Fail<Technician>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await loadFormData();
    return true;
  }

  /// Agenda visita usando o primeiro cliente e o primeiro tecnico.
  Future<bool> scheduleVisit(String title, {DateTime? scheduledAt}) async {
    final currentClients = clients.peek();
    final currentTechnicians = technicians.peek();
    if (currentClients.isEmpty || currentTechnicians.isEmpty) {
      _publishError('Cadastre um cliente e um tecnico antes de agendar.');
      return false;
    }
    final result = await _useCases.scheduleVisit(
      title: title,
      clientId: currentClients.first.id,
      technicianId: currentTechnicians.first.id,
      scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
      checklist: _defaultChecklist(),
    );
    if (result is Fail<Visit>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await refresh();
    return true;
  }

  /// Checklist padrao aplicado a toda visita nova (POC).
  List<ChecklistItem> _defaultChecklist() => [
    for (final label in _defaultChecklistLabels)
      if (ChecklistItem.create(description: label) case Ok<ChecklistItem>(
        :final value,
      ))
        value,
  ];

  static const _defaultChecklistLabels = [
    'Conferir equipamento',
    'Testar conexao',
    'Registrar atendimento',
  ];

  /// Inicia a visita [visitId] via `KortexCommand`.
  Future<bool> startVisit(int visitId) async {
    final result = await startCommand.execute(visitId);
    if (result == null) {
      _publishError('Nao foi possivel iniciar a visita.');
      return false;
    }
    if (result is Fail<Visit>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await refresh();
    return true;
  }

  /// Conclui a visita [visitId].
  Future<bool> completeVisit(int visitId) async {
    final result = await _useCases.completeVisit(visitId);
    if (result is Fail<Visit>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await refresh();
    return true;
  }

  /// Marca/desmarca o item [index] do checklist da visita [visitId].
  Future<bool> toggleChecklistItem(int visitId, int index) async {
    final result = await _useCases.toggleChecklistItem(visitId, index);
    if (result is Fail<Visit>) {
      _publishError(result.message);
      return false;
    }
    error.value = '';
    await refresh();
    return true;
  }

  /// Alterna a exibicao do dialog de nova visita.
  void toggleNewVisitDialog() {
    showNewVisitDialog.value = !showNewVisitDialog.peek();
  }

  /// Limpa a mensagem de erro (apos exibida em `SnackBar`).
  void clearError() {
    error.value = '';
  }

  static VisitStatus? _statusFromWire(String wire) {
    if (wire.isEmpty) return null;
    final parsed = VisitStatus.parse(wire);
    return parsed is Ok<VisitStatus> ? parsed.value : null;
  }

  void _publishError(String message) {
    error.value = message;
  }
}
