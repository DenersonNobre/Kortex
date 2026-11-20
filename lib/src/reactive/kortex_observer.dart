/// Grafo de observação e transação reativa (`KortexTracker`, batch).
///
/// SRP: rastrear qual observador lê qual nó, e consolidar notificações em
/// lote com fila deduplicada. NÃO faz: armazenar valores, derivar computados
/// ou executar efeitos (isso é papel dos nós e observadores).
///
/// Patterns: Observer (assinatura explícita) + Unit of Work (batch com
/// flush no fechamento mais externo, inclusive sob exceção).
/// Dependências: apenas `dart:core` (puro — sem Flutter, sem `BuildContext`).
library;

import 'kortex_disposable.dart';

/// Recebe o aviso de que um nó foi lido ou mudou.
///
/// Chamado em dois momentos: durante a coleta de dependências (dentro de
/// `KortexTracker.runWithObserver`) e no despacho de mudanças. Cabe ao
/// observador distinguir coleta de invalidação pelo próprio estado.
abstract interface class IKortexObserver {
  /// Reage à leitura ou mudança de [node].
  void onRead(IKortexReactiveNode node);
}

/// Fonte observável que gerencia assinantes e descarte.
abstract interface class IKortexReactiveNode implements IKortexDisposable {
  /// Assina [observer] (idempotente).
  void addObserver(IKortexObserver observer);

  /// Remove [observer] (sem efeito se ausente).
  void removeObserver(IKortexObserver observer);

  /// Libera assinantes. Leitura posterior via tracker não reassina.
  @override
  void dispose();
}

/// Moldura de rastreamento: observador ativo + coletor opcional de nós.
class _TrackingFrame {
  _TrackingFrame(this.observer, this.onTrack);

  final IKortexObserver observer;
  final void Function(IKortexReactiveNode)? onTrack;
}

/// Fila deduplicada de notificações pendentes (um aviso por observador).
class _PendingFlush {
  final Map<IKortexObserver, IKortexReactiveNode> _entries = {};

  /// Enfileira [observer] avisado por [node] (primeiro nó vence).
  void add(IKortexReactiveNode node, IKortexObserver observer) {
    _entries.putIfAbsent(observer, () => node);
  }

  /// Despacha tudo e esvazia a fila.
  void flush() {
    if (_entries.isEmpty) return;
    final snapshot = Map.of(_entries);
    _entries.clear();
    _notifyEach(snapshot);
  }

  void _notifyEach(Map<IKortexObserver, IKortexReactiveNode> snapshot) {
    for (final entry in snapshot.entries) {
      _notifyOne(entry.key, entry.value);
    }
  }

  void _notifyOne(IKortexObserver observer, IKortexReactiveNode node) {
    observer.onRead(node);
  }
}

/// Coordenador interno do rastreamento reativo (não exportado no barrel).
///
/// Pilha de molduras (`runWithObserver`/`recordRead`), contador de
/// profundidade de lote (`batch`) e suspensão de rastreio (`untracked`).
class KortexTracker {
  KortexTracker._();

  static final List<_TrackingFrame> _frames = [];
  static final _PendingFlush _pending = _PendingFlush();
  static var _batchDepth = 0;

  /// Executa [action] coletando leituras em [observer].
  static T runWithObserver<T>(
    IKortexObserver observer,
    T Function() action, {
    void Function(IKortexReactiveNode)? onTrack,
  }) {
    _frames.add(_TrackingFrame(observer, onTrack));
    try {
      return action();
    } finally {
      _frames.removeLast();
    }
  }

  /// Registra a leitura de [node] pelo observador do topo da pilha.
  ///
  /// Sem moldura ativa, não faz nada (leitura fora de rastreio).
  static void recordRead(IKortexReactiveNode node) {
    if (_frames.isEmpty) return;
    _trackInTopFrame(node);
  }

  /// Agenda [observers] de [node]: imediato fora de lote, fila dentro.
  static void notifyChange(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    if (_batchDepth > 0) {
      _stageAll(node, observers);
      return;
    }
    _dispatchNow(node, observers);
  }

  /// Agrupa mutações: observadores recebem um aviso ao sair do lote externo.
  ///
  /// Sob exceção, descarrega a fila mesmo assim (estado já mutou).
  static void batch(void Function() action) {
    _batchDepth++;
    try {
      action();
    } finally {
      _batchDepth--;
      _flushIfOutermost();
    }
  }

  /// Executa [action] sem registrar leituras (suspende a pilha).
  static T untracked<T>(T Function() action) {
    if (_frames.isEmpty) return action();
    return _runDetached(action);
  }

  static void _trackInTopFrame(IKortexReactiveNode node) {
    final frame = _frames.last;
    final observer = frame.observer;
    node.addObserver(observer);
    observer.onRead(node);
    _notifyTrack(frame, node);
  }

  static void _notifyTrack(_TrackingFrame frame, IKortexReactiveNode node) {
    final onTrack = frame.onTrack;
    if (onTrack == null) return;
    onTrack(node);
  }

  static void _stageAll(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    for (final observer in observers) {
      _pending.add(node, observer);
    }
  }

  static void _dispatchNow(
    IKortexReactiveNode node,
    Set<IKortexObserver> observers,
  ) {
    final snapshot = List.of(observers);
    for (final observer in snapshot) {
      observer.onRead(node);
    }
  }

  static void _flushIfOutermost() {
    if (_batchDepth > 0) return;
    _pending.flush();
  }

  static T _runDetached<T>(T Function() action) {
    final suspended = List.of(_frames);
    _frames.clear();
    try {
      return action();
    } finally {
      _frames.addAll(suspended);
    }
  }
}

/// Agrupa mutações de sinais sem glitches (ver [KortexTracker.batch]).
void kortexBatch(void Function() action) => KortexTracker.batch(action);

/// Lê sinais sem registrar dependência (ver [KortexTracker.untracked]).
T kortexUntracked<T>(T Function() action) => KortexTracker.untracked(action);
