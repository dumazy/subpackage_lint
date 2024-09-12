import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

class SubpackageLintOptions {
  factory SubpackageLintOptions.fromConfig(
      CustomLintConfigs configs, LintCode code) {
    final optionsJson = configs.rules[code.name]?.json;
    var excludeGlobs = <Glob>[];
    var directories = <String>[];

    if (optionsJson != null) {
      final exclude = optionsJson['exclude'] as YamlList?;
      if (exclude != null) {
        excludeGlobs = exclude.map((e) => Glob(e as String)).toList();
      }

      final dirs = optionsJson['directories'] as YamlList?;
      if (dirs != null) {
        directories = dirs.cast<String>();
      }
    }

    return SubpackageLintOptions(excludeGlobs, directories);
  }

  SubpackageLintOptions(
    this.excludeGlobs,
    this.directories,
  );

  final List<Glob> excludeGlobs;
  final List<String> directories;
}
