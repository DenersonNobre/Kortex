import 'package:kortex_sqlite/kortex_sqlite.dart';

void main() {
  const IResult<int, String> ok = Success(1);
  assert(ok.getOrNull() == 1);
}
