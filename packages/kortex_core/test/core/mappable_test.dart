import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  test('IMappable deriva JSON de toMap', () {
    final dto = _TransportDto('value');

    expect(dto.toJson(), '{"value":"value"}');
  });
}

class _TransportDto extends IMappable {
  _TransportDto(this.value);

  final String value;

  @override
  Map<String, dynamic> toMap() => {'value': value};
}
