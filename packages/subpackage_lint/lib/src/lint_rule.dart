import 'package:analyzer/dart/ast/ast.dart';

import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show AnalysisErrorType, AnalysisError, AnalysisErrorSeverity, Location;

abstract class LintRule {
  LintRule({
    required this.node,
    required this.path,
    required this.unit,
  });

  final AstNode node;
  final String path;
  final CompilationUnit unit;

  String get message;
  AnalysisErrorSeverity get severity => AnalysisErrorSeverity.ERROR;
  String get code => runtimeType.toString();

  AnalysisError? run();

  AnalysisError reportLintFor({
    required AstNode node,
    required String path,
  }) {
    final lineInfo = unit.lineInfo;
    final begin = lineInfo.getLocation(node.beginToken.charOffset);
    final end = lineInfo.getLocation(node.endToken.charOffset);
    final location = Location(
      path,
      node.offset,
      node.length,
      begin.lineNumber,
      begin.columnNumber,
      endLine: end.lineNumber,
      endColumn: end.columnNumber,
    );

    return AnalysisError(
      severity,
      AnalysisErrorType.LINT,
      location,
      message,
      code,
      hasFix: false,
    );
  }
}
