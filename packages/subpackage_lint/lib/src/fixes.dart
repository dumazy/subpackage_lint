import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'codes.dart' as codes;
import 'util/path_util.dart';

/// Registers all quick fixes with the plugin [registry].
void registerFixes(PluginRegistry registry) {
  registry
    ..registerFixForRule(
      codes.avoidRelativeSubpackageImport,
      _ConvertToPackageImport.new,
    )
    ..registerFixForRule(
      codes.avoidRelativeImportFromOtherSubpackage,
      _ConvertToPackageImport.new,
    )
    ..registerFixForRule(
      codes.preferRelativeImportFromSameSubpackage,
      _ConvertToRelativeImport.new,
    )
    ..registerFixForRule(
      codes.avoidSrcImportFromSameSubpackage,
      _RemoveSrcFromImport.new,
    )
    ..registerFixForRule(
      codes.avoidSrcImportFromOtherSubpackage,
      _ImportBarrelInstead.new,
    );
}

/// Base for fixes that rewrite the URI of the offending import directive.
abstract class _ImportUriFix extends ResolvedCorrectionProducer {
  _ImportUriFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  /// Computes the replacement URI (without surrounding quotes), or `null` when
  /// no safe fix can be produced.
  String? computeNewUri(ImportDirective directive);

  /// The minimal relative URI from this file to [directive]'s resolved target,
  /// or `null` when the target can't be resolved.
  String? relativeUriToTarget(ImportDirective directive) {
    final targetPath =
        directive.libraryImport?.importedLibrary?.firstFragment.source.fullName;
    if (targetPath == null) return null;
    return relativeImportUri(fromFile: file, targetPath: targetPath);
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final directive = node.thisOrAncestorOfType<ImportDirective>();
    if (directive == null) return;

    final newUri = computeNewUri(directive);
    if (newUri == null || newUri.isEmpty) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(directive.uri), "'$newUri'");
    });
  }
}

/// Replaces a relative import with the resolved `package:` URI of its target.
class _ConvertToPackageImport extends _ImportUriFix {
  _ConvertToPackageImport({required super.context});

  static const _fixKind = FixKind(
    'subpackage_lint.convert_to_package_import',
    50,
    "Convert to a 'package:' import",
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String? computeNewUri(ImportDirective directive) =>
      directive.libraryImport?.importedLibrary?.uri.toString();
}

/// Replaces a `package:` import of a same-subpackage file with a relative one.
class _ConvertToRelativeImport extends _ImportUriFix {
  _ConvertToRelativeImport({required super.context});

  static const _fixKind = FixKind(
    'subpackage_lint.convert_to_relative_import',
    50,
    'Convert to a relative import',
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String? computeNewUri(ImportDirective directive) =>
      relativeUriToTarget(directive);
}

/// Rewrites a `src`-routed relative import within the same subpackage to the
/// minimal `src`-free relative path (e.g. `../src/code.dart` -> `code.dart`).
class _RemoveSrcFromImport extends _ImportUriFix {
  _RemoveSrcFromImport({required super.context});

  static const _fixKind = FixKind(
    'subpackage_lint.remove_src_from_import',
    50,
    "Remove '/src/' from the import",
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String? computeNewUri(ImportDirective directive) =>
      relativeUriToTarget(directive);
}

/// Rewrites a direct `src` import from another subpackage to its barrel file.
class _ImportBarrelInstead extends _ImportUriFix {
  _ImportBarrelInstead({required super.context});

  static const _fixKind = FixKind(
    'subpackage_lint.import_barrel_instead',
    50,
    "Import the subpackage's barrel file",
  );

  @override
  FixKind get fixKind => _fixKind;

  @override
  String? computeNewUri(ImportDirective directive) {
    final uri = directive.uri.stringValue;
    if (uri == null) return null;
    final segments = uri.split('/');
    final srcIndex = segments.indexOf('src');
    // 'src' must exist and be preceded by the subpackage directory segment.
    if (srcIndex <= 0) return null;
    final subpackage = segments[srcIndex - 1];
    return [...segments.take(srcIndex), '$subpackage.dart'].join('/');
  }
}
