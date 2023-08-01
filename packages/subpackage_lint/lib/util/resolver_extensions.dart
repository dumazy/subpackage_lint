import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'path_util.dart';

extension ResolverExtensions on CustomLintResolver {
  Future<String> get relativePath async {
    final result = await getResolvedUnitResult();
    final uri = result.libraryElement.librarySource.uri;
    return getRelativePathFromPackageUri(uri);
  }
}
