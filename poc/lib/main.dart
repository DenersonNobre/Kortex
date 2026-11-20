/// Entrada do app de visitas tecnicas (POC do pacote `kortex`).
///
/// SRP: iniciar o app; toda a composicao vive em `app/visits_app.dart`.
/// NAO faz: regra de negocio nem composicao de dependencias.
///
/// Dependencias: Flutter + `kortex` (via `visits_app.dart`).
library;

import 'package:flutter/widgets.dart';

import 'app/visits_app.dart';

/// Ponto de entrada.
void main() => runApp(createVisitsApp());
