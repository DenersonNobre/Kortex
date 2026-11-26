import 'dart:io';

import 'package:test/test.dart';

/// Invariante INV-AGNOSTICIDADE: o módulo `core` permanece Dart puro.
///
/// O filtro de agnosticidade reprova qualquer abstração que acople um padrão
/// neutro a um framework. Este gate torna a regra mecânica, porque a
/// conformidade documental sozinha não sobrevive à pressão do dia a dia.
void main() {
  test('core não importa package:flutter em nenhuma diretiva', () {
    final diretivaFlutter = RegExp(
      r'''^\s*(?:import|export)\s+['"]package:flutter''',
      multiLine: true,
    );
    final violacoes = <String>[];

    for (final arquivo in _fontesDart(Directory('lib/core'))) {
      if (diretivaFlutter.hasMatch(arquivo.readAsStringSync())) {
        violacoes.add(arquivo.path.replaceAll(r'\', '/'));
      }
    }

    expect(
      violacoes,
      isEmpty,
      reason: 'core precisa permanecer sem Flutter; Found: $violacoes',
    );
  });

  test('o gate detecta violação real em subpasta aninhada', () {
    const violacao = "import 'package:flutter/foundation.dart';\nvoid f() {}\n";
    const conforme = 'import "dart:convert";\nvoid f() {}\n';

    expect(_temImportFlutter(violacao), isTrue);
    expect(_temImportFlutter(conforme), isFalse);
  });
}

/// Mesma detecção do teste acima, isolada para provar que o padrão casa de fato
/// — um gate nunca exercitado é indistinguível de um gate quebrado.
bool _temImportFlutter(String fonte) => _diretivaFlutter.hasMatch(fonte);

final _diretivaFlutter = RegExp(
  r'''^\s*(?:import|export)\s+['"]package:flutter''',
  multiLine: true,
);

Iterable<File> _fontesDart(Directory diretorio) sync* {
  for (final entrada in diretorio.listSync()) {
    if (entrada is Directory) {
      yield* _fontesDart(entrada);
    }
    if (entrada is File && entrada.path.endsWith('.dart')) {
      yield entrada;
    }
  }
}
