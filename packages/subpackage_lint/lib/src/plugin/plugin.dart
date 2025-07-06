import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'package:subpackage_lint/src/visitor.dart';

class SubpackageLintPlugin extends ServerPlugin {
  SubpackageLintPlugin({required super.resourceProvider});

  /// A map to store configuration per analysis context. This allows the plugin
  /// to support multiple projects (like in a monorepo) with different settings.
  final Map<String, List<Glob>> _excludedGlobsPerContext = {};

  @override
  List<String> get fileGlobsToAnalyze => ['**/*.dart'];

  @override
  String get name => 'subpackage_lint';

  @override
  String get version => '1.0.0';

  /// This method is called when the plugin is initialized with a collection
  /// of analysis contexts. This is the correct place to read configuration
  /// from each context's `analysis_options.yaml` file.
  // @override
  // Future<void> afterNewContextCollection(
  //     {required AnalysisContextCollection contextCollection}) async {
  //   // Clear any previous configurations.
  //   _excludedGlobsPerContext.clear();

  //   // Iterate over each context (each project folder the plugin is active in).
  //   for (final context in contextCollection.contexts) {
  //     final contextRootPath = context.contextRoot.root.path;
  //     final optionsFile = context.contextRoot.optionsFile;

  //     if (optionsFile == null || !optionsFile.exists) {
  //       continue;
  //     }

  //     try {
  //       final content = optionsFile.readAsStringSync();
  //       final optionsMap = loadYaml(content) as YamlMap?;
  //       if (optionsMap == null) continue;

  //       // Look for our plugin's configuration key.
  //       final pluginOptions = optionsMap['subpackage_lint'];

  //       // Check if the options are a YamlMap (which they should be).
  //       if (pluginOptions is YamlMap) {
  //         // Look for the 'exclude' key in our plugin's configuration.
  //         final excludeList = pluginOptions['exclude'];
  //         if (excludeList is YamlList) {
  //           // Convert the list of YamlNodes into a list of Glob objects.
  //           _excludedGlobsPerContext[contextRootPath] = excludeList.nodes
  //               .map((node) => node.value.toString())
  //               .map((globPattern) => Glob(globPattern))
  //               .toList();
  //         }
  //       }
  //     } catch (e) {
  //       // Could optionally send a notification to the client about a malformed file.
  //       // For now, we silently ignore it.
  //     }
  //   }
  // }

  // @override
// Future<void> afterNewContextCollection({
//   required AnalysisContextCollection contextCollection,
// }) async {
//   for (final context in contextCollection.contexts) {
//     final path = context.contextRoot.root.path;
//     final file = context.contextRoot.optionsFile;

//     if (file != null && file.exists) {
//       // Perform any necessary setup or analysis for the context
//       // For example, you might want to register custom rules or perform initial analysis
//       print(
//           'Setting up analysis for context at $path with options file ${file.path}');
//       _optionsMap[path] = context.getAnalysisOptionsForFile(file);
//     }
//   }

//   return super.afterNewContextCollection(
//     contextCollection: contextCollection,
//   );
// }

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    final contextRootPath = analysisContext.contextRoot.root.path;
    final excludedGlobs = _excludedGlobsPerContext[contextRootPath] ?? [];

    // First, check if the file should be excluded based on the configuration.
    // We get a relative path to match against the glob patterns.
    final relativePath = p.posix.relative(path, from: contextRootPath);
    final isExcluded = excludedGlobs.any((glob) => glob.matches(relativePath));

    if (isExcluded) {
      // If the file is excluded, send an empty list of errors and stop.
      channel.sendNotification(AnalysisErrorsParams(path, []).toNotification());
      return;
    }

    // We only want to analyze files inside the 'lib' directory.
    if (!p.split(path).contains('lib')) {
      channel.sendNotification(AnalysisErrorsParams(path, []).toNotification());
      return;
    }
    final result = await analysisContext.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) return;

    final visitor = SubpackageImportVisitor(
      filePath: path,
    );

    result.unit.accept(visitor);
    channel.sendNotification(
      AnalysisErrorsParams(path, visitor.errors).toNotification(),
    );
  }

  // /// This method is called by the IDE when the user requests quick fixes.
  // @override
  // Future<EditGetFixesResult> handleEditGetFixes(
  //     EditGetFixesParams parameters) async {
  //   final file = parameters.file;
  //   final errorOffset = parameters.offset;

  //   final result = await getResolvedUnitResult(file);

  //   final errors = _getErrorsForFile(result);
  //   // Find the error whose span contains the offset.
  //   AnalysisError? error;
  //   for (final e in errors) {
  //     final loc = e.location;
  //     if (loc.offset <= errorOffset && errorOffset <= loc.offset + loc.length) {
  //       error = e;
  //       break;
  //     }
  //   }

  //   if (error == null) {
  //     return EditGetFixesResult([]);
  //   }

  //   final node = NodeLocator(error.location.offset).searchWithin(result.unit);
  //   final importDirective = node?.thisOrAncestorOfType<ImportDirective>();
  //   if (importDirective == null) {
  //     return EditGetFixesResult([]);
  //   }

  //   String? replacement;
  //   String fixMessage = '';

  //   // Calculate the correct import string based on the error code.
  //   switch (error.code) {
  //     case 'avoid_package_import_for_same_package':
  //       fixMessage = 'Replace with relative import';
  //       final targetUri = importDirective.uri.stringValue;
  //       if (targetUri != null) {
  //         final targetPath = p.joinAll([
  //           result.session.analysisContext.contextRoot.root.path,
  //           'lib',
  //           ...Uri.parse(targetUri).pathSegments.skip(1),
  //         ]);
  //         replacement = p.relative(targetPath, from: p.dirname(file));
  //       }
  //       break;
  //     case 'avoid_src_import_from_other_subpackage':
  //       fixMessage = "Remove '/src' from import";
  //       final targetUri = importDirective.uri.stringValue;
  //       if (targetUri != null) {
  //         final segments = targetUri.split('/');
  //         final srcIndex = segments.indexOf('src');
  //         if (srcIndex > 0) {
  //           // Ensure 'src' is not the first segment
  //           final subpackage = segments[srcIndex - 1];
  //           replacement =
  //               [...segments.take(srcIndex), '$subpackage.dart'].join('/');
  //         }
  //       }
  //       break;
  //     case 'avoid_src_import_from_same_package':
  //       fixMessage = "Fix relative '/src' import";
  //       final targetUri = importDirective.uri.stringValue;
  //       if (targetUri != null) {
  //         replacement = targetUri.replaceAll('/src/', '/');
  //       }
  //       break;
  //   }

  //   if (replacement == null) {
  //     return EditGetFixesResult([]);
  //   }

  //   // Create the source code change.
  //   final change = SourceChange(
  //     fixMessage,
  //     edits: [
  //       SourceFileEdit(
  //         file,
  //         result.lineInfo.lineCount,
  //         edits: [
  //           SourceEdit(
  //             importDirective.uri.offset,
  //             importDirective.uri.length,
  //             "'$replacement'",
  //           ),
  //         ],
  //       ),
  //     ],
  //   );

  //   return EditGetFixesResult([
  //     AnalysisErrorFixes(error, fixes: [change])
  //   ]);
  // }

  // List<AnalysisError> _getErrorsForFile(ResolvedUnitResult result) {
  //   final visitor = _SubpackageImportVisitor(
  //     filePath: result.path,
  //     packageName: result.libraryElement.source.uri.pathSegments.first,
  //   );
  //   result.unit.accept(visitor);
  //   return visitor.errors;
  // }
}

// @override
// Future<void> afterNewContextCollection({
//   required AnalysisContextCollection contextCollection,
// }) async {
//   for (final context in contextCollection.contexts) {
//     final path = context.contextRoot.root.path;
//     final file = context.contextRoot.optionsFile;

//     if (file != null && file.exists) {
//       // Perform any necessary setup or analysis for the context
//       // For example, you might want to register custom rules or perform initial analysis
//       print(
//           'Setting up analysis for context at $path with options file ${file.path}');
//       _optionsMap[path] = context.getAnalysisOptionsForFile(file);
//     }
//   }

//   return super.afterNewContextCollection(
//     contextCollection: contextCollection,
//   );
// }
