/// Entrada do exemplo mínimo do `kortex` (aba Example do pub.dev).
///
/// SRP: compor o `KortexScope` raiz e rodar o `MaterialApp`.
/// NÃO faz: regra de negócio (vive no `CounterController`).
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'counter_controller.dart';
import 'counter_page.dart';

/// Monta o app com o escopo raiz do contador.
Widget createApp() => KortexScope(
  providers: [
    KortexProvider<CounterController>(create: (_) => CounterController()),
  ],
  child: const MaterialApp(home: CounterPage()),
);

/// Entrada do app de exemplo.
void main() => runApp(createApp());
