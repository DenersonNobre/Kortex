import 'dart:async';

import 'package:kortex/kortex.dart';
import 'package:kortex_persist/src/kortex_storage.dart';

/// Serializer converting a value of type [T] to a [String].
typedef KortexEncoder<T> = String Function(T value);

/// Deserializer converting a stored [String] back to [T].
typedef KortexDecoder<T> = T Function(String raw);

/// A [KortexSignal] that automatically hydrates from and persists to [IKortexStorage].
class KortexPersistedSignal<T> extends KortexSignal<T> {
  /// Creates a persisted signal bound to [key] in [_storage].
  KortexPersistedSignal({
    required this.key,
    required T initialValue,
    required this._storage,
    required this._encode,
    required this._decode,
    super.equals,
  }) : _initialValue = initialValue,
       super(initialValue) {
    hydrated = _hydrate();
  }

  /// Storage key used to read and write this signal's value.
  final String key;

  final T _initialValue;
  final IKortexStorage _storage;
  final KortexEncoder<T> _encode;
  final KortexDecoder<T> _decode;

  /// Completes once the initial hydration from [storage] finishes.
  late final Future<void> hydrated;

  Future<void> _hydrate() async {
    final raw = await _storage.read(key);
    if (isDisposed || raw == null) return;
    super.value = _decode(raw);
  }

  @override
  set value(T newValue) {
    final previous = peek();
    super.value = newValue;
    if (!isDisposed && peek() != previous) {
      unawaited(Future.sync(() => _storage.write(key, _encode(newValue))));
    }
  }

  /// Deletes the stored value from [storage] and resets to [initialValue].
  Future<void> clear() async {
    await _storage.delete(key);
    if (!isDisposed) {
      super.value = _initialValue;
    }
  }
}

/// Ergonomic shortcut for creating a [KortexPersistedSignal].
KortexPersistedSignal<T> kortexPersistedSignal<T>({
  required String key,
  required T initialValue,
  required IKortexStorage storage,
  required KortexEncoder<T> encode,
  required KortexDecoder<T> decode,
  KortexEquals<T>? equals,
}) => KortexPersistedSignal<T>(
  key: key,
  initialValue: initialValue,
  storage: storage,
  encode: encode,
  decode: decode,
  equals: equals,
);
