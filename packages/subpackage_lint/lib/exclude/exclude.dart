import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

const _excludeKey = 'exclude';

bool shouldExclude(
  String path,
  CustomLintConfigs configs,
  String code,
) {
  final rules = configs.rules[code]?.json;
  if (rules == null) return false;
  if (!rules.containsKey(_excludeKey)) return false;
  if (rules[_excludeKey] is! YamlList) return false;
  final excludes = rules[_excludeKey] as YamlList;

  return excludes.nodes
      .any((YamlNode exclude) => exclude.toString().matches(path));
}

extension ExcludeExtensions on String {
  bool matches(String path) {
    return Glob(this).matches(path);
  }
}
