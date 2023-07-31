import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:glob/glob.dart';

bool shouldExclude(
  String path,
  CustomLintConfigs configs,
  String code,
) {
  final rules = configs.rules[code]?.json;
  if (rules == null) return false;
  if (!rules.containsKey('exclude')) return false;
  if (rules['exclude'] is! List) return false;
  final excludes = rules['exclude'] as dynamic;

  bool shouldExclude = false;
  for (String exclude in excludes) {
    final glob = Glob('/**/$exclude');
    if (glob.matches(path)) {
      shouldExclude = true;
      break;
    }
  }
  return shouldExclude;
}
