import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../fix/remove_import.dart';
import '../path_util.dart';

class AvoidPackageImportForSamePackageRule extends DartLintRule {
  AvoidPackageImportForSamePackageRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_package_import_for_same_package',
    problemMessage: 'Avoid importing the package itself',
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

      if (importedPackageUri == filePackageUri && importedPackageUri == uri) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  @override
  List<Fix> getFixes() => [RemoveImportFix()];
}
