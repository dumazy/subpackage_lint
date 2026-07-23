import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'fixes.dart';
import 'rules.dart';

/// The subpackage_lint analyzer plugin.
///
/// Registers the subpackage import rules and their quick fixes with the Dart
/// analysis server. The rules are opt-in: enable them under the `diagnostics:`
/// section of the consuming project's `analysis_options.yaml`.
class SubpackageLintPlugin extends Plugin {
  @override
  String get name => 'subpackage_lint';

  @override
  void register(PluginRegistry registry) {
    for (final rule in allRules) {
      registry.registerLintRule(rule);
    }
    registerFixes(registry);
  }
}
