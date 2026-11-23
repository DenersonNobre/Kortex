String formatComplete(
  String source,
  RegExp accepted,
  int expectedLength,
  String mask,
) {
  final normalized = extract(source, accepted);
  if (normalized == null || normalized.length != expectedLength) {
    return source;
  }
  return applyMask(normalized, mask, allowLetters: false);
}

String? extract(String source, RegExp accepted) {
  final normalized = source.trim().toUpperCase();
  if (normalized.isEmpty || !accepted.hasMatch(normalized)) {
    return null;
  }
  return normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String applyMask(String value, String mask, {required bool allowLetters}) {
  final result = StringBuffer();
  var valueIndex = 0;
  for (final character in mask.split('')) {
    if (character == '#' || character == 'A') {
      if (valueIndex >= value.length) {
        break;
      }
      final isLetter = RegExp(r'[A-Z]').hasMatch(value[valueIndex]);
      if ((character == '#' && isLetter) ||
          (character == 'A' && isLetter && !allowLetters)) {
        break;
      }
      result.write(value[valueIndex]);
      valueIndex++;
      continue;
    }

    if (valueIndex < value.length) {
      result.write(character);
    }
  }
  return result.toString();
}
