import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _SubpackagePlugin();

class _SubpackagePlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidSrcImportRule(),
      ];
}

class AvoidSrcImportRule extends DartLintRule {
  AvoidSrcImportRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_src_import',
    problemMessage: 'Avoid importing from src',
    correctionMessage: 'Import from package instead',
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
      if (_isValidImport(uri, context.pubspec.name)) return;
      reporter.reportErrorForNode(_code, node);
    });
  }

  @override
  List<Fix> getFixes() => [
        _UsePackageImportFix(),
      ];
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
      final uri = node.uri.stringValue;
      final appName = context.pubspec.name;
      if (uri == null) return;
      if (_isValidImport(uri, appName)) return;

      final isAbsoluteImport = uri.startsWith('package:');
      final sourceFactory = node.element!.library.context.sourceFactory;

      final absoluteUri = isAbsoluteImport
          ? uri
          : _convertToAbsoluteUri(uri, sourceFactory, appName);

      final packageUri = _getPackageUriForAbsoluteImport(absoluteUri);

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Change to package import',
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

String _getPackageUriForAbsoluteImport(String uri) {
  final parts = uri.split('/').takeWhile((value) => value != 'src');
  final packageUri = parts.join('/') + '/' + parts.last + '.dart';
  return packageUri;
}

String _convertToAbsoluteUri(
    String uri, SourceFactory sourceFactory, String appName) {
  return 'package:$appName/${sourceFactory.pathToUri(uri).toString()}';
}

bool _isValidImport(String uri, String appName) {
  final isAbsoluteImport = uri.startsWith('package:');
  final isAbsoluteAppImport = uri.startsWith('package:$appName');
  if (!uri.contains('src')) return true;
  // Don't fix if it's an absolute import from another package
  if (isAbsoluteImport && !isAbsoluteAppImport) return true;
  return false;
}
