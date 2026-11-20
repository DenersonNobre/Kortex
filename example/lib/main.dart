/// Entry point of the minimal `kortex` example (pub.dev Example tab).
///
/// SRP: compose the root `KortexScope` and run the `MaterialApp`. It does
/// NOT hold business rules (those live in the `CounterController`).
library;

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'counter_controller.dart';
import 'counter_page.dart';

/// Builds the app with the root counter scope.
Widget createApp() => KortexScope(
  providers: [
    KortexProvider<CounterController>(create: (_) => CounterController()),
  ],
  child: const MaterialApp(home: CounterPage()),
);

/// Entry point of the example app.
void main() => runApp(createApp());
