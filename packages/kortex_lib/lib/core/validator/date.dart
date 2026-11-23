import 'validators.dart';

/// Pure calendar validation for formatted date text and [DateTime].
///
/// No Flutter, no `intl`, no locale: the format uses `dd`/`d`, `MM`/`M`,
/// `yyyy` tokens with `.`, `/` or `-` separators, and the year window is
/// configurable instead of fixed.
bool isValidDateText(
  String? value, {
  String format = 'dd/MM/yyyy',
  int minYear = 1900,
  int maxYear = 2100,
}) {
  if (value == null || value.isEmpty) {
    return false;
  }
  final pattern = _buildRegexFromFormat(format);
  if (!pattern.hasMatch(value)) {
    return false;
  }
  final parts = _extractDateParts(value, format);
  final year = parts['year']!;
  final month = parts['month']!;
  final day = parts['day']!;
  if (year < minYear || year > maxYear) {
    return false;
  }
  if (month < 1 || month > 12) {
    return false;
  }
  final maxDay = _daysInMonth(year)[month - 1];
  return day >= 1 && day <= maxDay;
}

/// Range check for already-parsed dates, without text-format concerns.
bool isValidDate(DateTime? value, {int minYear = 1900, int maxYear = 2100}) {
  if (value == null) {
    return false;
  }
  return value.year >= minYear && value.year <= maxYear;
}

/// Optional-field validator for formatted date text.
class ValidDate extends Validator<String?> {
  ValidDate({
    this.format = 'dd/MM/yyyy',
    this.minYear = 1900,
    this.maxYear = 2100,
    String? message,
  }) : super((value) {
         if (value == null || value.isEmpty) {
           return null;
         }
         if (isValidDateText(
           value,
           format: format,
           minYear: minYear,
           maxYear: maxYear,
         )) {
           return null;
         }
         return message ?? 'Informe uma data válida';
       });

  final String format;
  final int minYear;
  final int maxYear;
}

/// Optional-field validator for parsed dates.
class ValidDateTime extends Validator<DateTime?> {
  ValidDateTime({this.minYear = 1900, this.maxYear = 2100, String? message})
    : super((value) {
        if (value == null) {
          return null;
        }
        if (isValidDate(value, minYear: minYear, maxYear: maxYear)) {
          return null;
        }
        return message ?? 'Informe uma data válida';
      });

  final int minYear;
  final int maxYear;
}

RegExp _buildRegexFromFormat(String format) {
  final pattern = format.replaceAllMapped(RegExp(r'(dd|d|MM|M|yyyy|\.|/|-)'), (
    match,
  ) {
    switch (match[0]) {
      case 'dd':
        return r'(\d{2})';
      case 'd':
        return r'(\d{1,2})';
      case 'MM':
        return r'(\d{2})';
      case 'M':
        return r'(\d{1,2})';
      case 'yyyy':
        return r'(\d{4})';
      case '/':
      case '-':
      case '.':
        return r'(?:\.|/|-)';
      default:
        return match[0]!;
    }
  });
  return RegExp('^$pattern\$');
}

Map<String, int> _extractDateParts(String value, String format) {
  final match = _buildRegexFromFormat(format).firstMatch(value);
  if (match == null) {
    throw ArgumentError('Data inválida para o formato especificado.');
  }
  final formatParts = format.split(RegExp(r'[\./-]')).map((part) {
    if (part.contains('d')) return part.contains('dd') ? 'dd' : 'd';
    if (part.contains('M')) return part.contains('MM') ? 'MM' : 'M';
    return part;
  }).toList();

  final parts = <String, int>{};
  var group = 1;
  for (final part in formatParts) {
    if (part == 'd' || part == 'dd') {
      parts['day'] = int.parse(match.group(group)!);
    } else if (part == 'M' || part == 'MM') {
      parts['month'] = int.parse(match.group(group)!);
    } else if (part == 'yyyy') {
      parts['year'] = int.parse(match.group(group)!);
    }
    group++;
  }
  return parts;
}

List<int> _daysInMonth(int year) {
  final days = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (_isLeapYear(year)) {
    days[1] = 29;
  }
  return days;
}

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
