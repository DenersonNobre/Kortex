import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../scope/kortex_provider.dart';
import '../scope/kortex_scope.dart';

/// Root application widget that establishes the root [KortexScope] and hosts
/// a [MaterialApp].
///
/// Ensures strict typing by strictly requiring [MaterialApp] and wraps it
/// with the provided [providers].
final class KortexMaterialApp extends StatelessWidget {
  /// Creates a [KortexMaterialApp].
  const KortexMaterialApp({
    super.key,
    required this.providers,
    required this.app,
  });

  /// Root providers exposed to the entire widget tree.
  final List<KortexProvider<Object>> providers;

  /// The root [MaterialApp] instance.
  final MaterialApp app;

  @override
  Widget build(BuildContext context) {
    return KortexScope(providers: providers, child: app);
  }
}

/// Root application widget that establishes the root [KortexScope] and hosts
/// a [CupertinoApp].
///
/// Ensures strict typing by strictly requiring [CupertinoApp] and wraps it
/// with the provided [providers].
final class KortexCupertinoApp extends StatelessWidget {
  /// Creates a [KortexCupertinoApp].
  const KortexCupertinoApp({
    super.key,
    required this.providers,
    required this.app,
  });

  /// Root providers exposed to the entire widget tree.
  final List<KortexProvider<Object>> providers;

  /// The root [CupertinoApp] instance.
  final CupertinoApp app;

  @override
  Widget build(BuildContext context) {
    return KortexScope(providers: providers, child: app);
  }
}
