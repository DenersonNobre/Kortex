// Par chave/valor imutável usado como identificador em operações de dados
// (update/delete/readById) — agrupa o nome do campo e seu valor em vez de
// argumentos soltos `(id, String key)`.

class KeyValue {
  final String key;
  final String value;

  const KeyValue({required this.key, required this.value});

  @override
  String toString() => 'KeyValue($key: $value)';

  @override
  bool operator ==(Object other) =>
      other is KeyValue && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}
