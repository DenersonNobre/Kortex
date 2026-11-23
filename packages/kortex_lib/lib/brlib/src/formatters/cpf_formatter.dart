import 'mask_utils.dart';

/// Formata CPF completo; devolve [source] intacto se o formato não corresponder.
String formatCpf(String source) =>
    formatComplete(source, RegExp(r'^[0-9.()\-/\s]+$'), 11, '###.###.###-##');
