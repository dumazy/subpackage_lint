import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
///
/// All fixes work from the *resolved* target of the import rather than from
/// the text of the URI, so they produce the right result regardless of how
/// convoluted the original path was (`../../feature/src/../src/x.dart`, ...).
abstract class _ImportUriFix extends ResolvedCorrectionProducer {
  _ImportUriFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  /// Computes the replacement URI (without surrounding quotes), or `null` when
  /// no safe fix can be produced.
  String? computeNewUri(ImportDirective directive);

  /// The library imported by [directive], or `null` when it can't be resolved.
  LibraryElement? importedLibrary(ImportDirective directive) =>
      directive.libraryImport?.importedLibrary;

  /// The absolute path on disk of the library imported by [directive].
  String? targetPath(ImportDirective directive) =>
      importedLibrary(directive)?.firstFragment.source.fullName;

  /// The minimal relative URI from this file to [directive]'s resolved target,
  /// or `null` when the target can't be resolved.
  String? relativeUriToTarget(ImportDirective directive) {
    final target = targetPath(directive);
    if (target == null) return null;
    return relativeImportUri(fromFile: file, targetPath: target);
  }

  /// The `package:` URI of the barrel file of the subpackage owning the
  /// resolved target of [directive], or `null` when the target isn't inside a
  /// subpackage or has no `package:` URI (e.g. a file under `test/`).
  String? barrelUriForTarget(ImportDirective directive) {
    final library = importedLibrary(directive);
    final target = library?.firstFragment.source.fullName;
    if (library == null || target == null) return null;
    return barrelPackageUri(
      targetLibraryUri: library.uri,
      targetPath: target,
    )?.toString();
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final directive = node.thisOrAncestorOfType<ImportDirective>();
    if (directive == null) return;

    final newUri = computeNewUri(directive);
    if (newUri == null || newUri.isEmpty) return;
    // Nothing to do when the import already reads the way we'd rewrite it.
    if (newUri == directive.uri.stringValue) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(directive.uri), "'$newUri'");
    });
  }
}

/// Replaces a relative import with a `package:` import.
///
/// When the relative import reaches into another subpackage's private `src`
/// directory, the fix goes straight to that subpackage's barrel file rather
/// than producing a `package:` `src` import that would immediately be flagged
/// by `avoid_src_import_from_other_subpackage`.
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
  String? computeNewUri(ImportDirective directive) {
    final library = importedLibrary(directive);
    final target = library?.firstFragment.source.fullName;
    if (library == null || target == null) return null;
    // Only lib/ files have a `package:` URI; never write a `file:` import.
    if (!library.uri.isScheme('package')) return null;

    final subpackage = getSubpackageInfo(target);
    if (subpackage != null && isWithinSrc(subpackage, target)) {
      return barrelUriForTarget(directive);
    }
    return library.uri.toString();
  }
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
  String? computeNewUri(ImportDirective directive) =>
      barrelUriForTarget(directive);
}
