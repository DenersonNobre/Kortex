import 'package:kortex/kortex.dart';

const Object _absent = Object();

/// Synchronous validator returning an error message or `null` when valid.
typedef KortexValidator<T> = String? Function(T value);

/// Reactive form field with validation, `touched`/`dirty` tracking, and `reset()`.
class KortexField<T> implements IKortexDisposable {
  /// Creates a reactive field initialized with [initialValue].
  KortexField(
    T initialValue, {
    List<KortexValidator<T>> validators = const [],
    KortexEquals<T>? equals,
  }) : _initialValue = initialValue,
       _validators = List.unmodifiable(validators),
       _value = KortexSignal<T>(initialValue, equals: equals),
       _touched = KortexSignal<bool>(false),
       _dirty = KortexSignal<bool>(false),
       _error = KortexSignal<String?>(null);

  final T _initialValue;
  final List<KortexValidator<T>> _validators;
  final KortexSignal<T> _value;
  final KortexSignal<bool> _touched;
  final KortexSignal<bool> _dirty;
  final KortexSignal<String?> _error;

  /// Read-only reactive view of the field value.
  IKortex<T> get valueSignal => _value.readonly;

  /// Read-only reactive view of whether the field was blurred or validated.
  IKortex<bool> get touched => _touched.readonly;

  /// Read-only reactive view of whether the value was modified by user input.
  IKortex<bool> get dirty => _dirty.readonly;

  /// Read-only reactive view of the current validation error, if any.
  IKortex<String?> get error => _error.readonly;

  /// Current field value (tracked when read inside `KortexWatch`/`KortexComputed`).
  T get value => _value.value;

  /// Updates the field value, marks it `dirty`, and re-validates if `touched`.
  set value(T next) {
    kortexBatch(() {
      _value.value = next;
      _dirty.value = true;
      if (_touched.peek()) {
        _error.value = _runValidators(next);
      }
    });
  }

  /// Whether the current value passes all validators.
  bool get isValid => _runValidators(_value.value) == null;

  /// Marks the field as `touched`.
  void markTouched() {
    _touched.value = true;
  }

  /// Marks the field as `touched`, runs all validators, and returns `isValid`.
  bool validate() {
    final nextError = _runValidators(_value.peek());
    kortexBatch(() {
      _touched.value = true;
      _error.value = nextError;
    });
    return nextError == null;
  }

  /// Resets the field to [nextValue] (or `initialValue` when omitted) and
  /// clears flags/errors.
  void reset([Object? nextValue = _absent]) {
    final resolved = identical(nextValue, _absent)
        ? _initialValue
        : nextValue as T;
    kortexBatch(() {
      _value.value = resolved;
      _touched.value = false;
      _dirty.value = false;
      _error.value = null;
    });
  }

  String? _runValidators(T candidate) {
    for (final validator in _validators) {
      final message = validator(candidate);
      if (message != null) return message;
    }
    return null;
  }

  @override
  void dispose() {
    _value.dispose();
    _touched.dispose();
    _dirty.dispose();
    _error.dispose();
  }
}

/// Ergonomic shortcut for creating a [KortexField].
KortexField<T> kortexField<T>(
  T initialValue, {
  List<KortexValidator<T>> validators = const [],
  KortexEquals<T>? equals,
}) => KortexField<T>(initialValue, validators: validators, equals: equals);
