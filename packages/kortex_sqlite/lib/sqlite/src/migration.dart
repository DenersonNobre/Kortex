class Migration {
  Migration({required this.version, required List<String> scripts})
    : scripts = List.unmodifiable(scripts) {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Deve ser maior que zero.');
    }
  }

  final int version;
  final List<String> scripts;
}
