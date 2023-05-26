import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RemoveImportFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove import',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addDeletion(SourceRange(node.offset, node.length));
      });
    });
  }
}
