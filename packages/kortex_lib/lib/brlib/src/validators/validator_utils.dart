int cpfDigit(String digits) {
  var sum = 0;
  for (var index = 0; index < digits.length; index++) {
    sum += int.parse(digits[index]) * (digits.length + 1 - index);
  }
  final remainder = (sum * 10) % 11;
  return remainder == 10 ? 0 : remainder;
}

String? normalize(String? source, {required bool allowLetters}) {
  if (source == null) {
    return null;
  }

  final normalized = source.trim().toUpperCase();
  final acceptedCharacters = allowLetters
      ? RegExp(r'^[A-Z0-9./()\-\s]+$')
      : RegExp(r'^[0-9./()\-\s]+$');
  if (normalized.isEmpty || !acceptedCharacters.hasMatch(normalized)) {
    return null;
  }

  return normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

bool hasRepeatedChars(String value) =>
    value.split('').every((character) => character == value[0]);

bool isDigits(String value) => RegExp(r'^[0-9]+$').hasMatch(value);
