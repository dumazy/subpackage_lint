import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'rule/avoid_src_from_other.dart';
import 'rule/avoid_src_from_same.dart';
import 'rule/package_from_same.dart';

PluginBase createPlugin() => _SubpackagePlugin();

class _SubpackagePlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidSrcImportFromOtherSubpackageRule(),
        AvoidSrcImportFromSamePackageRule(),
        AvoidPackageImportForSamePackageRule(),
      ];
}
