import 'package:kortex_rest/kortex_rest.dart';

void main() {
  const IResult<int, String> ok = Success(200);
  assert(ok.getOrNull() == 200);
}
