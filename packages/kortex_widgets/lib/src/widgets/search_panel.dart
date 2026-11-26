import 'package:flutter/material.dart';
import 'package:kortex_core/kortex_core.dart' show Debouncer;

/// Campo de busca unificado com suporte opcional a [Debouncer], ícone e ação.
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
    this.label,
    this.hintText,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.debouncer,
    this.icon = Icons.search,
    this.action,
    this.border,
    this.enabled = true,
  }) : assert(
         onChanged != null || debouncer != null,
         'Informe onChanged ou debouncer em SearchPanel.',
       );

  final String? label;
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Debouncer<String>? debouncer;
  final IconData? icon;
  final Widget? action;
  final InputBorder? border;
  final bool enabled;

  void _handleChanged(String value) {
    debouncer?.call(value);
    onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      onChanged: _handleChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon == null ? null : Icon(icon),
        border: border ?? const OutlineInputBorder(),
        suffixIcon: action == null
            ? null
            : Padding(padding: const EdgeInsets.all(8), child: action),
      ),
    );
  }
}
