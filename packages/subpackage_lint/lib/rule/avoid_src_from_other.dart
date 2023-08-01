import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../exclude/exclude.dart';
import '../util/path_util.dart';
import '../util/resolver_extensions.dart';

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
  ) async {
    final path = await resolver.relativePath;
    if (shouldExclude(path, configs, _code.name)) return;

    context.registry.addImportDirective((node) {
      if (isSrcImportFromOtherPackage(node)) {
        reporter.reportErrorForOffset(_code, node.uri.offset, node.uri.length);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_UsePackageImportFix()];
}

bool isSrcImportFromOtherPackage(ImportDirective node) {
  final uri = node.uri.stringValue;

  // no URI
  if (uri == null || uri.isEmpty) return false;

  final element = node.element;

  // Unresolved
  if (element == null) return false;

  final importedId = element.importedLibrary?.identifier;
  final fileId = element.library.identifier;

  // Not focusing on dart: imports
  if (importedId == null) return false;

  final importedPackageUri = getPackageUriForAbsoluteImport(importedId);
  final filePackageUri = getPackageUriForAbsoluteImport(fileId);

  // Same package
  if (importedPackageUri == filePackageUri) return false;

  // already a package import, so no src
  if (uri == importedPackageUri) return false;

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
