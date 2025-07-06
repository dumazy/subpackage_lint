import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:subpackage_lint/src/util/path_util.dart';

/// An AST Visitor that checks all import directives against our subpackage philosophy.
/// Example imports:
///
/// Good
/// import 'a_private_file.dart';
/// import '../some_public_file.dart';
/// import 'package:my_app/another_subpackage/another_subpackage.dart';
///
/// Bad
/// import '../src/a_private_file.dart';
/// import 'package:my_app/my_subpackage/my_subpackage.dart';
/// import 'package:my_app/my_subpackage/src/a_private_file.dart';
/// import '../another_subpackage/another_subpackage.dart';
/// import '../another_subpackage/src/a_private_file.dart';
/// import '../my_subpackage.dart';
class SubpackageImportVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<AnalysisError> errors = [];
  final SubpackageInfo? _sourceSubpackageInfo;

  SubpackageImportVisitor({required this.filePath})
      : _sourceSubpackageInfo = getSubpackageInfo(filePath);

  @override
  void visitImportDirective(ImportDirective node) {
    final importUriString = node.uri.stringValue;
    if (importUriString == null) return;
    final uri = Uri.tryParse(importUriString);
    if (uri == null || uri.isScheme('dart')) {
      return;
    }

    final importedLibrary = node.element?.importedLibrary;
    if (importedLibrary == null) return; // Unresolved import, can't check it.
    final targetPath = importedLibrary.source.fullName;
    final targetIsSubpackage = isSubpackage(targetPath);
    final targetSubpackageInfo = getSubpackageInfo(targetPath);

    if (targetIsSubpackage) {
      _validateSubpackageImport(
        node,
        uri,
        targetSubpackageInfo,
      );
    } else {
      _validateOtherImport(
        node,
        uri,
        targetSubpackageInfo,
      );
    }
  }

  /// Validates imports of a subpackage barrel file.
  void _validateSubpackageImport(
    ImportDirective node,
    Uri uri,
    SubpackageInfo? targetSubpackageInfo,
  ) {
    final isPackageImport = uri.isScheme('package');
    final targetOwnsSubpackage = _sourceSubpackageInfo != null &&
        targetSubpackageInfo != null &&
        _sourceSubpackageInfo.path == targetSubpackageInfo.path;
    if (targetOwnsSubpackage) {
      errors.add(_createError(
        node,
        'avoid_own_subpackage_import',
        "Avoid importing the subpackage's own barrel file",
        correction:
            "Use relative imports for files within the same subpackage.",
      ));
    } else if (!isPackageImport) {
      errors.add(_createError(
        node,
        'avoid_relative_subpackage_import',
        "Use package: imports for subpackage imports.",
      ));
    }
  }

  /// Validates imports that are not subpackage barrel files.
  void _validateOtherImport(
    ImportDirective node,
    Uri uri,
    SubpackageInfo? targetSubpackageInfo,
  ) {
    final isPackageImport = uri.isScheme('package');
    final targetInCurrentSubpackage = _sourceSubpackageInfo != null &&
        targetSubpackageInfo != null &&
        _sourceSubpackageInfo.path == targetSubpackageInfo.path;

    if (targetInCurrentSubpackage) {
      // If the target is in the same subpackage, we check it
      _validateInternalImport(isPackageImport, node, uri);
    } else {
      _validateExternalImport(isPackageImport, node, targetSubpackageInfo);
    }
  }

  /// Validates imports for non-barrel files from within the current subpackage.
  void _validateInternalImport(
      bool isPackageImport, ImportDirective node, Uri uri) {
    if (isPackageImport) {
      errors.add(_createError(
        node,
        'prefer_relative_import_from_same_subpackage',
        "Prefer relative imports for files in the same subpackage.",
      ));
    } else {
      if (uri.pathSegments.contains('src')) {
        errors.add(_createError(
          node,
          'avoid_src_import_from_same_package',
          "Avoid using '/src/' in relative imports within the same subpackage.",
        ));
      }
    }
  }

  /// Validates imports for non-barrel files from other subpackages.
  void _validateExternalImport(bool isPackageImport, ImportDirective node,
      SubpackageInfo? targetSubpackageInfo) {
    if (!isPackageImport) {
      errors.add(_createError(
        node,
        'avoid_relative_import_from_other_subpackage',
        "Use package: imports for files in other subpackages.",
      ));
    } else {
      if (targetSubpackageInfo != null) {
        errors.add(_createError(
          node,
          'avoid_src_import_from_other_subpackage',
          "Avoid using '/src/' in imports from other subpackages.",
          correction:
              "Try importing the subpackage ${targetSubpackageInfo.name} instead.",
        ));
      }
    }
  }

  AnalysisError _createError(
    ImportDirective node,
    String code,
    String message, {
    String? correction,
  }) {
    return AnalysisError(
      AnalysisErrorSeverity.WARNING,
      AnalysisErrorType.LINT,
      Location(filePath, node.uri.offset, node.uri.length, 0, 0),
      message,
      code,
      correction: correction,
      hasFix: false,
    );
  }
}
