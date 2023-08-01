import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'path_util.dart';

extension ResolverExtensions on CustomLintResolver {
  /// Returns the relative path from the package root.
  Future<String> get relativePath async {
    final result = await getResolvedUnitResult();
    final uri = result.libraryElement.librarySource.uri;
    return getRelativePathFromPackageUri(uri);
  }
}
