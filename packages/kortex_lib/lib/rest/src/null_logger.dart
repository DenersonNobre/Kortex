typedef HttpLogger = void Function(String message);

class NullLogger {
  const NullLogger();

  void call(String message) {}
}
