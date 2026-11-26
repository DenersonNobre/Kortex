import 'package:kortex_core/kortex_core.dart';

void main() {
  const IResult<int, String> ok = Success(42);
  assert(ok.getOrNull() == 42);
}
