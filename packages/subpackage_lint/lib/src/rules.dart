import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'codes.dart' as codes;
import 'exclude_config.dart';
import 'import_classifier.dart';

/// All lint rules defined by this plugin, in registration order.
List<AnalysisRule> get allRules => [
  AvoidOwnSubpackageImport(),
  AvoidRelativeSubpackageImport(),
  PreferRelativeImportFromSameSubpackage(),
  AvoidSrcImportFromSameSubpackage(),
  AvoidRelativeImportFromOtherSubpackage(),
  AvoidSrcImportFromOtherSubpackage(),
];

/// Base class for the subpackage rules.
///
/// Each rule shares the same import classification (see [classifyImport]) and
/// only reports the [violation] it is responsible for. Keeping the rules
/// separate lets consumers enable, disable, and re-severity each one
/// individually via the `diagnostics:` section of `analysis_options.yaml`.
abstract class SubpackageRule extends AnalysisRule {
  SubpackageRule({required super.name, required super.description});

  /// The single violation this rule reports.
  SubpackageViolation get violation;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(
      this,
      _ImportVisitor(this, context.package?.root.path),
    );
  }
}

class _ImportVisitor extends SimpleAstVisitor<void> {
  _ImportVisitor(this.rule, this.packageRoot);

  final SubpackageRule rule;

  /// The root of the package being analyzed, used to resolve the configured
  /// `exclude` globs. `null` when the file is not part of a package.
  final String? packageRoot;

  @override
  void visitImportDirective(ImportDirective node) {
    final unit = node.root;
    if (unit is! CompilationUnit) return;
    final sourceFilePath = unit.declaredFragment?.source.fullName;
    if (sourceFilePath == null) return;

    // Skip files the consumer excluded from the subpackage rules.
    final packageRoot = this.packageRoot;
    if (packageRoot != null &&
        ExcludeConfig.forPackage(
          packageRoot,
        ).excludes(sourceFilePath, packageRoot)) {
      return;
    }

    final analysis = classifyImport(node, sourceFilePath);
    if (analysis == null || analysis.violation != rule.violation) return;

    rule.reportAtNode(node.uri);
  }
}

class AvoidOwnSubpackageImport extends SubpackageRule {
  AvoidOwnSubpackageImport()
    : super(
        name: 'avoid_own_subpackage_import',
        description:
            "Avoid importing the subpackage's own barrel file from within it.",
      );

  @override
  DiagnosticCode get diagnosticCode => codes.avoidOwnSubpackageImport;

  @override
  SubpackageViolation get violation => SubpackageViolation.ownSubpackageImport;
}

class AvoidRelativeSubpackageImport extends SubpackageRule {
  AvoidRelativeSubpackageImport()
    : super(
        name: 'avoid_relative_subpackage_import',
        description: "Use 'package:' imports when importing a subpackage.",
      );

  @override
  DiagnosticCode get diagnosticCode => codes.avoidRelativeSubpackageImport;

  @override
  SubpackageViolation get violation =>
      SubpackageViolation.relativeSubpackageImport;
}

class PreferRelativeImportFromSameSubpackage extends SubpackageRule {
  PreferRelativeImportFromSameSubpackage()
    : super(
        name: 'prefer_relative_import_from_same_subpackage',
        description:
            'Prefer relative imports for files in the same subpackage.',
      );

  @override
  DiagnosticCode get diagnosticCode =>
      codes.preferRelativeImportFromSameSubpackage;

  @override
  SubpackageViolation get violation =>
      SubpackageViolation.preferRelativeFromSameSubpackage;
}

class AvoidSrcImportFromSameSubpackage extends SubpackageRule {
  AvoidSrcImportFromSameSubpackage()
    : super(
        name: 'avoid_src_import_from_same_subpackage',
        description:
            "Avoid using '/src/' in relative imports within a subpackage.",
      );

  @override
  DiagnosticCode get diagnosticCode => codes.avoidSrcImportFromSameSubpackage;

  @override
  SubpackageViolation get violation =>
      SubpackageViolation.srcImportFromSameSubpackage;
}

class AvoidRelativeImportFromOtherSubpackage extends SubpackageRule {
  AvoidRelativeImportFromOtherSubpackage()
    : super(
        name: 'avoid_relative_import_from_other_subpackage',
        description: "Use 'package:' imports for files in other subpackages.",
      );

  @override
  DiagnosticCode get diagnosticCode =>
      codes.avoidRelativeImportFromOtherSubpackage;

  @override
  SubpackageViolation get violation =>
      SubpackageViolation.relativeImportFromOtherSubpackage;
}

class AvoidSrcImportFromOtherSubpackage extends SubpackageRule {
  AvoidSrcImportFromOtherSubpackage()
    : super(
        name: 'avoid_src_import_from_other_subpackage',
        description:
            "Avoid importing from the 'src' directory of another subpackage.",
      );

  @override
  DiagnosticCode get diagnosticCode => codes.avoidSrcImportFromOtherSubpackage;

  @override
  SubpackageViolation get violation =>
      SubpackageViolation.srcImportFromOtherSubpackage;
}
