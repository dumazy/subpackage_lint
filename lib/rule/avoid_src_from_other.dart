import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fix/package_import_fix.dart';
import '../path_util.dart';

class AvoidSrcImportFromOtherSubpackageRule extends DartLintRule {
  AvoidSrcImportFromOtherSubpackageRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_src_import_from_other_subpackage',
    problemMessage: 'Avoid importing from `src` directory of other subpackage',
    correctionMessage: 'Import the subpackage instead',
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

      // Same package
      if (importedPackageUri == filePackageUri) return;

      // already a package import
      if (uri == importedPackageUri) return;

      reporter.reportErrorForNode(_code, node);
    });
  }

  @override
  List<Fix> getFixes() => [UsePackageImportFix()];
}
