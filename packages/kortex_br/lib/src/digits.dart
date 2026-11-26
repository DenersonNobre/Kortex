/// Extracts only ASCII digits from [input].
String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

/// Alias for [digitsOnly] when removing mask characters.
String unmask(String input) => digitsOnly(input);
