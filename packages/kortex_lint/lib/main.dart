import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:kortex_lint/src/rules/avoid_kortex_signal_in_build.dart';
import 'package:kortex_lint/src/rules/avoid_undisposed_kortex_signal.dart';
import 'package:kortex_lint/src/rules/prefer_i_prefix_for_abstractions.dart';

/// Entrypoint for the Kortex analyzer plugin.
final plugin = KortexLintPlugin();

/// Registers Kortex static analysis rules.
class KortexLintPlugin extends Plugin {
  @override
  String get name => 'kortex_lint';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(AvoidUndisposedKortexSignal());
    registry.registerWarningRule(AvoidKortexSignalInBuild());
    registry.registerWarningRule(PreferIPrefixForAbstractions());
  }
}
