/// `StatelessWidget` page with a scope-resolved controller.
///
/// SRP: resolve `TController` in the `KortexScope` and delegate to
/// `buildPage`. It does NOT manage state (that is the signals' job),
/// navigate or provide dependencies.
///
/// Patterns: Template Method (`build` calls `buildPage`).
/// Dependencies: Flutter + the `reactive`/`scope` layers (no global GetView).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import '../scope/scope.dart';

/// Stateless page whose controller comes from the ancestor `KortexScope`.
abstract class IKortexPage<TController extends IKortexController>
    extends StatelessWidget {
  /// Creates the page (no `StatefulWidget` for business state).
  const IKortexPage({super.key});

  /// Resolves the controller through `BuildContext` (fails without a scope).
  TController controllerOf(BuildContext context) =>
      context.readKortex<TController>();

  /// Builds the UI with the resolved [controller].
  Widget buildPage(BuildContext context, TController controller);

  @override
  Widget build(BuildContext context) =>
      buildPage(context, controllerOf(context));
}
