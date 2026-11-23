import 'package:kortex/kortex.dart';
import 'package:kortex_forms/src/kortex_field.dart';

/// Groups [KortexField] instances for coordinated `validate()`, `reset()`, and `dispose()`.
class KortexForm implements IKortexDisposable {
  /// Creates a form managing [fields].
  KortexForm(List<KortexField<dynamic>> fields)
    : fields = List.unmodifiable(fields);

  /// Managed fields in this form.
  final List<KortexField<dynamic>> fields;

  /// Whether every field currently passes validation.
  bool get isValid => fields.every((field) => field.isValid);

  /// Validates all fields and returns `true` only if every field is valid.
  bool validate() {
    var allValid = true;
    kortexBatch(() {
      for (final field in fields) {
        if (!field.validate()) {
          allValid = false;
        }
      }
    });
    return allValid;
  }

  /// Resets all managed fields to their initial values.
  void reset() {
    kortexBatch(() {
      for (final field in fields) {
        field.reset();
      }
    });
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
  }
}

/// Ergonomic shortcut for creating a [KortexForm].
KortexForm kortexForm(List<KortexField<dynamic>> fields) => KortexForm(fields);
