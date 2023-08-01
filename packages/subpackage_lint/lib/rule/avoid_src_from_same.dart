import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../exclude/exclude.dart';
import '../util/path_util.dart';
import '../util/resolver_extensions.dart';

class AvoidSrcImportFromSamePackageRule extends DartLintRule {
  final CustomLintConfigs configs;
  AvoidSrcImportFromSamePackageRule(this.configs) : super(code: _code);

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
  ) async {
    final path = await resolver.relativePath;
    if (shouldExclude(path, configs, _code.name)) return;

    context.registry.addImportDirective((node) {
      if (isSamePackageAbsoluteImport(node)) {
        reporter.reportErrorForOffset(_code, node.uri.offset, node.uri.length);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_UseRelativeImportFix()];
}

bool isSamePackageAbsoluteImport(ImportDirective node) {
  final uri = node.uri.stringValue;
  if (uri == null || uri.isEmpty) return false; // No uri specified

  final element = node.element;
  if (element == null) return false; // Unresolved import

  final importedId = element.importedLibrary?.identifier;
  final fileId = element.library.identifier;

  if (importedId == null) return false; // Not focusing on dart: imports

  final importedPackageUri = getPackageUriForAbsoluteImport(importedId);
  final filePackageUri = getPackageUriForAbsoluteImport(fileId);

  if (!uri.contains('src')) return false; // doesn't contain src

  if (importedPackageUri != filePackageUri) return false; // from other package

  return true;
}

class _UseRelativeImportFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      if (!isSamePackageAbsoluteImport(node)) return;

      final element = node.element!;
      final importedLibrary = element.importedLibrary!.identifier;
      final library = element.library.identifier;

      final packageUri = getRelativeImportUri(importedLibrary, library);

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use relative import instead',
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
