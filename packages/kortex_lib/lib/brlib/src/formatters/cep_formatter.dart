import 'mask_utils.dart';

/// Formata CEP completo sem inferir se o endereço existe.
String formatCep(String source) =>
    formatComplete(source, RegExp(r'^[0-9.()\-/\s]+$'), 8, '#####-###');
