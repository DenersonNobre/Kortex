import 'package:flutter/services.dart';

/// Aplica uma máscara em que `#` representa um dígito decimal.
class DigitMaskInputFormatter extends TextInputFormatter {
  DigitMaskInputFormatter({
    required this.mask,
    required this.maxCharacters,
    this.allowLetters = false,
  }) : assert(maxCharacters > 0);

  final String mask;
  final int maxCharacters;
  final bool allowLetters;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final accepted = allowLetters ? RegExp('[A-Z0-9]') : RegExp('[0-9]');
    final edited = _deleteDigitBesideSeparator(oldValue, newValue, accepted);
    final normalized = edited.text
        .toUpperCase()
        .split('')
        .where(accepted.hasMatch)
        .join();
    final limited = normalized.length > maxCharacters
        ? normalized.substring(0, maxCharacters)
        : normalized;
    final text = _applyMask(limited, mask, allowLetters: allowLetters);
    final characterCursor = _characterCountBefore(
      edited.text,
      edited.selection.extentOffset,
      accepted,
    );
    final cursor = _cursorForCharacters(
      text,
      characterCursor.clamp(0, limited.length),
      accepted,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}

/// Backspace/delete sobre um separador da máscara (`.`, `-`, `/`, `)`…)
/// apaga só o separador, que a remascaração reinsere: o toque não remove
/// nada e o dígito vizinho exige dois toques. Quando exatamente um
/// caractere não alfanumérico foi apagado, remove também o dígito
/// imediatamente anterior ao cursor, para que um toque sempre apague um
/// dígito. Deleção de letra (CNPJ alfanumérico) não entra na regra.
TextEditingValue _deleteDigitBesideSeparator(
  TextEditingValue oldValue,
  TextEditingValue newValue,
  RegExp accepted,
) {
  if (!newValue.selection.isCollapsed ||
      newValue.text.length != oldValue.text.length - 1) {
    return newValue;
  }
  final cursor = newValue.selection.extentOffset;
  if (cursor < 0 || cursor >= oldValue.text.length) {
    return newValue;
  }
  if (RegExp('[A-Z0-9]').hasMatch(oldValue.text[cursor].toUpperCase())) {
    return newValue;
  }
  if (oldValue.text.replaceRange(cursor, cursor + 1, '') != newValue.text) {
    return newValue;
  }
  final before = newValue.text.substring(0, cursor);
  for (var index = before.length - 1; index >= 0; index--) {
    if (accepted.hasMatch(before[index].toUpperCase())) {
      return newValue.copyWith(
        text: newValue.text.replaceRange(index, index + 1, ''),
        selection: TextSelection.collapsed(offset: index),
      );
    }
  }
  return newValue;
}

String _applyMask(String value, String mask, {required bool allowLetters}) {
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

int _characterCountBefore(String text, int offset, RegExp accepted) {
  final boundedOffset = offset.clamp(0, text.length);
  return accepted
      .allMatches(text.substring(0, boundedOffset).toUpperCase())
      .length;
}

int _cursorForCharacters(String text, int characterCount, RegExp accepted) {
  if (characterCount == 0) {
    return 0;
  }

  var seenCharacters = 0;
  for (var index = 0; index < text.length; index++) {
    if (accepted.hasMatch(text[index])) {
      seenCharacters++;
      if (seenCharacters == characterCount) {
        return index + 1;
      }
    }
  }
  return text.length;
}
