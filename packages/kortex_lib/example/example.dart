import 'package:kortex_lib/kortex_lib.dart';

void main() {
  const IResult<int, String> ok = Success(42);
  assert(ok.getOrNull() == 42);
}
