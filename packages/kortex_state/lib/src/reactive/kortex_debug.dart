/// Debug-only observability hooks for the Kortex reactive layer.
///
/// SRP: emit opt-in lifecycle and state-change events inside `assert(...)`
/// blocks so release builds incur zero overhead (`INV-05` pure Dart).
library;

/// Base sealed event emitted by [KortexDebug].
sealed class IKortexDebugEvent {
  /// Creates a debug event with an optional [label].
  const IKortexDebugEvent({this.label});

  /// Optional diagnostic label identifying the primitive.
  final String? label;
}

/// Emitted when a reactive primitive is created.
final class KortexDebugCreated extends IKortexDebugEvent {
  /// Creates a creation event.
  const KortexDebugCreated({super.label, required this.type});

  /// Runtime type name of the created primitive.
  final String type;
}

/// Emitted when a reactive primitive updates its value.
final class KortexDebugUpdated extends IKortexDebugEvent {
  /// Creates an update event.
  const KortexDebugUpdated({super.label, required this.type, this.value});

  /// Runtime type name of the updated primitive.
  final String type;

  /// New value (for diagnostic inspection).
  final Object? value;
}

/// Emitted when a reactive primitive or controller is disposed.
final class KortexDebugDisposed extends IKortexDebugEvent {
  /// Creates a disposal event.
  const KortexDebugDisposed({super.label, required this.type});

  /// Runtime type name of the disposed primitive.
  final String type;
}

/// Observer contract for receiving [IKortexDebugEvent]s in debug mode.
abstract interface class IKortexDebugObserver {
  /// Called whenever a debug event is emitted.
  void onEvent(IKortexDebugEvent event);
}

/// Global opt-in debug hook (no-op in release mode).
abstract final class KortexDebug {
  /// Active debug observer, or `null` when disabled.
  static IKortexDebugObserver? observer;

  /// Emits [event] to [observer] only when assertions (debug mode) are enabled.
  static void emit(IKortexDebugEvent event) {
    assert(() {
      observer?.onEvent(event);
      return true;
    }());
  }
}
