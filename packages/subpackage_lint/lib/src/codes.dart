import 'package:analyzer/error/error.dart';

/// The diagnostic codes reported by this plugin, one per rule.
///
/// Kept in a single place so both the rules (which report them) and the fixes
/// (which register against them) refer to the same instances.
const avoidOwnSubpackageImport = LintCode(
  'avoid_own_subpackage_import',
  "Avoid importing the subpackage's own barrel file.",
  correctionMessage: 'Use relative imports for files in the same subpackage.',
  severity: DiagnosticSeverity.WARNING,
);

const avoidRelativeSubpackageImport = LintCode(
  'avoid_relative_subpackage_import',
  "Use a 'package:' import when importing a subpackage.",
  correctionMessage: "Replace the relative import with a 'package:' import.",
  severity: DiagnosticSeverity.WARNING,
);

const preferRelativeImportFromSameSubpackage = LintCode(
  'prefer_relative_import_from_same_subpackage',
  'Prefer a relative import for a file in the same subpackage.',
  correctionMessage: "Replace the 'package:' import with a relative import.",
  severity: DiagnosticSeverity.WARNING,
);

const avoidSrcImportFromSameSubpackage = LintCode(
  'avoid_src_import_from_same_subpackage',
  "Avoid using '/src/' in a relative import within the same subpackage.",
  correctionMessage: "Remove '/src/' from the import.",
  severity: DiagnosticSeverity.WARNING,
);

const avoidRelativeImportFromOtherSubpackage = LintCode(
  'avoid_relative_import_from_other_subpackage',
  "Use a 'package:' import for a file in another subpackage.",
  correctionMessage: "Replace the relative import with a 'package:' import.",
  severity: DiagnosticSeverity.WARNING,
);

const avoidSrcImportFromOtherSubpackage = LintCode(
  'avoid_src_import_from_other_subpackage',
  "Avoid importing from the 'src' directory of another subpackage.",
  correctionMessage: "Import the subpackage's barrel file instead.",
  severity: DiagnosticSeverity.WARNING,
);
