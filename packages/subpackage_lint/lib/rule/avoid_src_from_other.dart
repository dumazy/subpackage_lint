import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../exclude/exclude.dart';
import '../path_util.dart';

class AvoidSrcImportFromOtherSubpackageRule extends DartLintRule {
  final CustomLintConfigs configs;
  AvoidSrcImportFromOtherSubpackageRule(this.configs) : super(code: _code);

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
    if (shouldExclude(resolver.path, configs, _code.name)) return;
    context.registry.addImportDirective((node) {
      if (isSrcImportFromOtherPackage(node)) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_UsePackageImportFix()];
}

bool isSrcImportFromOtherPackage(ImportDirective node) {
  final uri = node.uri.stringValue;
  if (uri == null || uri.isEmpty) return false; // no URI

  final element = node.element;
  if (element == null) return false; // Unresolved

  final importedId = element.importedLibrary?.identifier;
  final fileId = element.library.identifier;

  if (importedId == null) return false; // Not focusing on dart: imports

  final importedPackageUri = getPackageUriForAbsoluteImport(importedId);
  final filePackageUri = getPackageUriForAbsoluteImport(fileId);

  if (importedPackageUri == filePackageUri) return false; // Same package

  if (uri == importedPackageUri)
    return false; // already a package import, so no src

  return true;
}

class _UsePackageImportFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      if (!isSrcImportFromOtherPackage(node)) return;
      final importedLibraryId = node.element!.importedLibrary!.identifier;
      final packageUri = getPackageUriForAbsoluteImport(importedLibraryId);

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Change to package import',
        priority: 100,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          SourceRange(node.uri.offset, node.uri.length),
          "'$packageUri'",
        );
      });
    });
  }
}
