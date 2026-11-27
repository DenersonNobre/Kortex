import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_forms/kortex_forms.dart';

/// Pure Dart `dd/MM/yyyy` formatter and parser (no `intl` dependency).
abstract final class KortexDateBr {
  /// Formats [date] as `dd/MM/yyyy`.
  static String format(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Parses `dd/MM/yyyy` strictly (returns `null` for invalid calendar dates
  /// such as `31/02/2026`, without throwing).
  static DateTime? tryParse(String? input) {
    if (input == null) return null;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  /// Masks digits progressively as `dd/MM/yyyy`.
  static String mask(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    final c = d.length > 8 ? d.substring(0, 8) : d;
    if (c.length <= 2) return c;
    if (c.length <= 4) return '${c.substring(0, 2)}/${c.substring(2)}';
    return '${c.substring(0, 2)}/${c.substring(2, 4)}/${c.substring(4)}';
  }

  /// Validates a [DateTimeRange], returning an error when `end < start`.
  static String? validateRange(DateTimeRange? range) {
    if (range == null) return null;
    if (range.end.isBefore(range.start)) {
      return 'Data final deve ser igual ou posterior a inicial';
    }
    return null;
  }
}

/// Masked `dd/MM/yyyy` date input + picker bound to `KortexField<DateTime?>`.
class KortexDateField extends StatefulWidget {
  /// Creates a date field bound to [field].
  const KortexDateField({
    super.key,
    required this.field,
    this.label = 'Data',
    this.firstDate,
    this.lastDate,
    this.invalidDateMessage = 'Data invalida',
  });

  /// Reactive form field.
  final KortexField<DateTime?> field;

  /// Input label.
  final String label;

  /// Earliest selectable date in picker.
  final DateTime? firstDate;

  /// Latest selectable date in picker.
  final DateTime? lastDate;

  /// Error shown when typed text is not a valid `dd/MM/yyyy` date.
  final String invalidDateMessage;

  @override
  State<KortexDateField> createState() => _KortexDateFieldState();
}

class _KortexDateFieldState extends State<KortexDateField> {
  late final TextEditingController _controller;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    final initial = widget.field.value;
    _controller = TextEditingController(
      text: initial == null ? '' : KortexDateBr.format(initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.field.value ?? now,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    if (picked == null || !mounted) return;
    _controller.text = KortexDateBr.format(picked);
    setState(() => _parseError = null);
    widget.field.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final fieldError = widget.field.touched.value
            ? widget.field.error.value
            : null;
        return TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            TextInputFormatter.withFunction((_, newValue) {
              final masked = KortexDateBr.mask(newValue.text);
              return TextEditingValue(
                text: masked,
                selection: TextSelection.collapsed(offset: masked.length),
              );
            }),
          ],
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'dd/mm/aaaa',
            errorText: _parseError ?? fieldError,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
          ),
          onChanged: (text) {
            if (text.trim().isEmpty) {
              setState(() => _parseError = null);
              widget.field.value = null;
              return;
            }
            final parsed = KortexDateBr.tryParse(text);
            if (parsed == null) {
              setState(() => _parseError = widget.invalidDateMessage);
              widget.field.value = null;
              return;
            }
            setState(() => _parseError = null);
            widget.field.value = parsed;
          },
        );
      },
    );
  }
}

/// Date range picker field bound to `KortexField<DateTimeRange?>`.
class KortexDateRangeField extends StatelessWidget {
  /// Creates a date range field bound to [field].
  const KortexDateRangeField({
    super.key,
    required this.field,
    this.label = 'Periodo',
    this.firstDate,
    this.lastDate,
  });

  /// Reactive form field.
  final KortexField<DateTimeRange?> field;

  /// Input label.
  final String label;

  /// Earliest selectable date.
  final DateTime? firstDate;

  /// Latest selectable date.
  final DateTime? lastDate;

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      initialDateRange: field.value,
    );
    if (picked == null) return;
    field.value = picked;
    field.validate();
  }

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final range = field.value;
        final text = range == null
            ? ''
            : '${KortexDateBr.format(range.start)} - ${KortexDateBr.format(range.end)}';
        final rangeError = KortexDateBr.validateRange(range);
        final fieldError = field.touched.value ? field.error.value : null;
        return InkWell(
          onTap: () => _pickRange(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: rangeError ?? fieldError,
              suffixIcon: const Icon(Icons.date_range),
            ),
            child: Text(text.isEmpty ? 'Selecionar periodo' : text),
          ),
        );
      },
    );
  }
}
