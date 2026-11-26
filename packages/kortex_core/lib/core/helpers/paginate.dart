import 'dart:convert';

class Paginate {
  final int? take;
  final int? skip;

  const Paginate({this.take = 15, this.skip = 0});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Paginate && other.skip == skip && other.take == take;
  }

  @override
  int get hashCode => skip.hashCode ^ take.hashCode;

  Map<String, dynamic> toMap() {
    return {'take': take.toString(), 'skip': skip.toString()};
  }

  factory Paginate.fromMap(Map<String, dynamic> map) {
    return Paginate(take: _toInt(map['take']), skip: _toInt(map['skip']));
  }

  static int? _toInt(dynamic value) {
    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  String toJson() => json.encode(toMap());

  factory Paginate.fromJson(String source) =>
      Paginate.fromMap(json.decode(source));
}
