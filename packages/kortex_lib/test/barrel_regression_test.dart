import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  test('barrel re-exporta simbolos de kortex_core, kortex_rest e kortex_sqlite', () {
    const IResult<int, String> ok = Success(42);
    expect(ok.getOrNull(), 42);

    expect(RestClient, isNotNull);
    expect(Migration, isNotNull);
  });
}
