import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
      if (isPackageImportFromSamePackage(node)) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveImportFix()];
}

bool isPackageImportFromSamePackage(ImportDirective node) {
  final uri = node.uri.stringValue;
  if (uri == null) return false;

  final element = node.element;
  if (element == null) return false; // Unresolved

  final importedId = element.importedLibrary?.identifier;
  final fileId = element.library.identifier;

  if (importedId == null) return false; // Not focusing on dart: imports

  final importedPackageUri = getPackageUriForAbsoluteImport(importedId);
  final filePackageUri = getPackageUriForAbsoluteImport(fileId);

  return importedPackageUri == filePackageUri && importedPackageUri == uri;
}

class _RemoveImportFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      if (!isPackageImportFromSamePackage(node)) return;
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove import',
        priority:
            100, // No specific reason, but if lower than 2 "ignore warning" was suggested first, instead of the fix
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addDeletion(SourceRange(node.uri.offset, node.uri.length));
      });
    });
  }
}
