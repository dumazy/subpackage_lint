import 'package:analyzer/dart/ast/ast.dart';

import 'util/path_util.dart';

/// The kinds of subpackage-import violations this plugin can detect.
enum SubpackageViolation {
  /// A file imports its own subpackage's barrel file.
  ownSubpackageImport,

  /// A subpackage barrel is imported with a relative import.
  relativeSubpackageImport,

  /// A file within a subpackage imports a sibling file with a `package:` import.
  preferRelativeFromSameSubpackage,

  /// A relative import within the same subpackage reaches through `src`.
  srcImportFromSameSubpackage,

  /// A file in another subpackage is imported with a relative import.
  relativeImportFromOtherSubpackage,

  /// A `src` file of another subpackage is imported directly.
  srcImportFromOtherSubpackage,
}

/// The result of classifying a single import directive.
typedef ImportAnalysis = ({
  SubpackageViolation violation,
  SubpackageInfo? targetSubpackage,
});

/// Classifies [node] against the subpackage import rules.
///
/// [sourceFilePath] is the absolute path of the file containing the import.
/// Returns `null` when the import is fine, unresolvable, or not relevant (e.g.
/// `dart:` imports).
ImportAnalysis? classifyImport(ImportDirective node, String sourceFilePath) {
  final importUri = node.uri.stringValue;
  if (importUri == null || importUri.isEmpty) return null;

  final parsedUri = Uri.tryParse(importUri);
  if (parsedUri == null || parsedUri.isScheme('dart')) return null;

  // Resolve the imported library to its file on disk. Unresolved imports
  // (e.g. a typo, or a package not yet fetched) can't be classified.
  final targetPath =
      node.libraryImport?.importedLibrary?.firstFragment.source.fullName;
  if (targetPath == null) return null;

  final sourceSubpackage = getSubpackageInfo(sourceFilePath);
  final targetSubpackage = getSubpackageInfo(targetPath);

  return classifyResolvedImport(
    isPackageImport: parsedUri.isScheme('package'),
    targetIsBarrel: isSubpackageBarrel(targetPath),
    uriHasSrcSegment: parsedUri.pathSegments.contains('src'),
    sourceIsWithinSrc: sourceSubpackage != null &&
        isWithinSrc(sourceSubpackage, sourceFilePath),
    sourceSubpackage: sourceSubpackage,
    targetSubpackage: targetSubpackage,
  );
}

/// Applies the subpackage import rules to the already-resolved facts about an
/// import. Kept separate from [classifyImport] so the full decision table can
/// be exercised without a running analyzer.
///
/// - [isPackageImport]: the URI uses the `package:` scheme.
/// - [targetIsBarrel]: the target is a subpackage's barrel library file.
/// - [uriHasSrcSegment]: the written URI contains a `src` path segment.
/// - [sourceIsWithinSrc]: the source file lives inside its subpackage's `src`.
/// - [sourceSubpackage]/[targetSubpackage]: the subpackages owning each file,
///   or `null` when the file belongs to no subpackage.
ImportAnalysis? classifyResolvedImport({
  required bool isPackageImport,
  required bool targetIsBarrel,
  required bool uriHasSrcSegment,
  required bool sourceIsWithinSrc,
  required SubpackageInfo? sourceSubpackage,
  required SubpackageInfo? targetSubpackage,
}) {
  final sameSubpackage = sourceSubpackage != null &&
      targetSubpackage != null &&
      sourceSubpackage.path == targetSubpackage.path;

  if (targetIsBarrel) {
    if (sameSubpackage) {
      return (
        violation: SubpackageViolation.ownSubpackageImport,
        targetSubpackage: targetSubpackage,
      );
    }
    if (!isPackageImport) {
      return (
        violation: SubpackageViolation.relativeSubpackageImport,
        targetSubpackage: targetSubpackage,
      );
    }
    return null;
  }

  if (sameSubpackage) {
    if (isPackageImport) {
      return (
        violation: SubpackageViolation.preferRelativeFromSameSubpackage,
        targetSubpackage: targetSubpackage,
      );
    }
    // Only flag when the source file is itself inside `src`: only then can the
    // target be reached with a `src`-free relative path. A file above `src`
    // (e.g. a public file next to the barrel) has no such alternative.
    if (sourceIsWithinSrc && uriHasSrcSegment) {
      return (
        violation: SubpackageViolation.srcImportFromSameSubpackage,
        targetSubpackage: targetSubpackage,
      );
    }
    return null;
  }

  // The remaining rules only concern crossing *into another subpackage*. When
  // the target isn't part of any subpackage (e.g. a plain `lib/domain/` file),
  // there is no boundary to protect, so any import style is fine.
  if (targetSubpackage == null) return null;

  if (!isPackageImport) {
    return (
      violation: SubpackageViolation.relativeImportFromOtherSubpackage,
      targetSubpackage: targetSubpackage,
    );
  }
  return (
    violation: SubpackageViolation.srcImportFromOtherSubpackage,
    targetSubpackage: targetSubpackage,
  );
}
