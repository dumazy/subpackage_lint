import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_util.dart';

class UseRelativeImportFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;
      final element = node.element;
      // Unresolved
      if (element == null) return;

      final importedLibrary = element.importedLibrary?.identifier;
      if (importedLibrary == null) return;
      final library = element.library.identifier;

      final packageUri = getRelativeImportUri(
        importedLibrary,
        library,
      );

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use relative import instead',
        priority: 1,
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
