import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fix/relative_import_fix.dart';
import '../path_util.dart';

class AvoidSrcImportFromSamePackageRule extends DartLintRule {
  AvoidSrcImportFromSamePackageRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_src_import_from_same_package',
    problemMessage: 'Avoid importing from `src` directory of same package',
    correctionMessage: 'Use a relative import instead',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      final element = node.element;
      // Unresolved
      if (element == null) return;

      final importedId = element.importedLibrary?.identifier;
      final fileId = element.library.identifier;

      if (importedId == null) return; // Not focusing on dart: imports

      final importedPackageUri = getPackageUriForAbsoluteImport(importedId);
      final filePackageUri = getPackageUriForAbsoluteImport(fileId);

      if (!uri.contains('src')) return;

      // Other package
      if (importedPackageUri != filePackageUri) return;

      reporter.reportErrorForNode(_code, node);
    });
  }

  @override
  List<Fix> getFixes() => [UseRelativeImportFix()];
}
