import 'result.dart';

/// Falha tipada de uma transição que não foi permitida.
class StateTransitionFailure<S> {
  const StateTransitionFailure({required this.from, required this.to});

  final S from;
  final S to;

  String get code => 'TRANSITION_NOT_ALLOWED';
}

/// Máquina de estados pura com uma guarda opcional de transições.
///
/// Quando [transitions] é nulo, qualquer estado de destino é aceito. Quando
/// informado, somente os pares origem-destino declarados são aceitos.
class StateMachine<S> {
  StateMachine({required S initial, Set<(S, S)>? transitions})
    : _currentState = initial,
      _transitions = transitions == null ? null : Set.unmodifiable(transitions);

  S _currentState;
  final Set<(S, S)>? _transitions;

  S get currentState => _currentState;

  /// Informa se [next] pode ser alcançado a partir do estado atual.
  bool canTransitionTo(S next) =>
      _transitions == null || _transitions.contains((_currentState, next));

  /// Aplica [next] ou devolve uma falha tipada sem alterar o estado.
  IResult<S, StateTransitionFailure<S>> transitionTo(S next) {
    final current = _currentState;
    if (!canTransitionTo(next)) {
      return Failure(StateTransitionFailure<S>(from: current, to: next));
    }

    _currentState = next;
    return Success(_currentState);
  }
}
