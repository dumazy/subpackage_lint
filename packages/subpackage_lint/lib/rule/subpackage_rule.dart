import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:subpackage_lint/util/resolver_extensions.dart';

import '../config/rule_config.dart';

abstract class SubpackageRule extends DartLintRule {
  SubpackageRule(CustomLintConfigs configs, LintCode code) : super(code: code) {
    options = SubpackageLintOptions.fromConfig(configs, code);
    _filesToAnalyze = options.directories.isEmpty
        ? ['**.dart']
        : options.directories.map((e) => '$e/**.dart').toList();
  }

  late final SubpackageLintOptions options;
  late final List<String> _filesToAnalyze;

  Future<bool> shouldExclude(CustomLintResolver resolver) async {
    final path = await resolver.relativePath;
    return options.excludeGlobs.any((glob) {
      final result = glob.matches(path);
      print('Checking ${path} against $glob: $result');
      return result;
    });
  }

  @override
  List<String> get filesToAnalyze => _filesToAnalyze;
}
