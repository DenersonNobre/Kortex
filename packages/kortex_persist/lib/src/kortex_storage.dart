import 'dart:async';

/// Pluggable key-value storage contract for `kortex_persist`.
abstract interface class IKortexStorage {
  /// Reads the raw serialized value for [key], or `null` if absent.
  FutureOr<String?> read(String key);

  /// Persists [value] under [key].
  FutureOr<void> write(String key, String value);

  /// Removes any persisted value for [key].
  FutureOr<void> delete(String key);
}

/// In-memory [IKortexStorage] implementation for tests and ephemeral state.
class KortexMemoryStorage implements IKortexStorage {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  void write(String key, String value) {
    _data[key] = value;
  }

  @override
  void delete(String key) {
    _data.remove(key);
  }
}
