import 'dart:async';

import 'package:kortex/kortex.dart';
import 'package:kortex_persist/src/kortex_storage.dart';

/// Serializer converting a value of type [T] to a [String].
typedef KortexEncoder<T> = String Function(T value);

/// Deserializer converting a stored [String] back to [T].
typedef KortexDecoder<T> = T Function(String raw);

/// Callback invoked when a storage read, write or delete fails.
typedef KortexPersistErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// A [KortexSignal] that automatically hydrates from and persists to [IKortexStorage].
class KortexPersistedSignal<T> extends KortexSignal<T> {
  /// Creates a persisted signal bound to [key] in [_storage].
  KortexPersistedSignal({
    required this.key,
    required T initialValue,
    required this._storage,
    required this._encode,
    required this._decode,
    this.onError,
    super.equals,
  }) : _initialValue = initialValue,
       super(initialValue) {
    hydrated = _hydrate();
  }

  /// Storage key used to read and write this signal's value.
  final String key;

  /// Optional handler for storage errors.
  final KortexPersistErrorHandler? onError;

  final T _initialValue;
  final IKortexStorage _storage;
  final KortexEncoder<T> _encode;
  final KortexDecoder<T> _decode;

  var _hasLocalMutation = false;
  Object? _lastError;
  Future<void> _pendingOp = Future<void>.value();

  /// Last storage error observed, or `null` if the last operation succeeded.
  Object? get lastError => _lastError;

  /// Completes once the initial hydration from [storage] finishes.
  late final Future<void> hydrated;

  /// Waits for all queued storage operations to complete.
  Future<void> flush() => _pendingOp;

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key);
      _lastError = null;
      if (isDisposed || _hasLocalMutation || raw == null) return;
      super.value = _decode(raw);
    } catch (error, stackTrace) {
      _lastError = error;
      onError?.call(error, stackTrace);
    }
  }

  Future<void> _enqueue(FutureOr<void> Function() op) {
    final next = _pendingOp.then((_) async {
      try {
        await op();
        _lastError = null;
      } catch (error, stackTrace) {
        _lastError = error;
        onError?.call(error, stackTrace);
      }
    });
    _pendingOp = next;
    return next;
  }

  @override
  set value(T newValue) {
    final previous = peek();
    _hasLocalMutation = true;
    super.value = newValue;
    if (!isDisposed && peek() != previous) {
      unawaited(_enqueue(() => _storage.write(key, _encode(newValue))));
    }
  }

  /// Deletes the stored value from [storage] and resets to [initialValue].
  Future<void> clear() async {
    _hasLocalMutation = true;
    if (!isDisposed) {
      super.value = _initialValue;
    }
    await _enqueue(() => _storage.delete(key));
  }
}

/// Ergonomic shortcut for creating a [KortexPersistedSignal].
KortexPersistedSignal<T> kortexPersistedSignal<T>({
  required String key,
  required T initialValue,
  required IKortexStorage storage,
  required KortexEncoder<T> encode,
  required KortexDecoder<T> decode,
  KortexPersistErrorHandler? onError,
  KortexEquals<T>? equals,
}) => KortexPersistedSignal<T>(
  key: key,
  initialValue: initialValue,
  storage: storage,
  encode: encode,
  decode: decode,
  onError: onError,
  equals: equals,
);
