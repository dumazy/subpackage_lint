String getPackageUriForAbsoluteImport(String uri) {
  if (!uri.contains('src')) return uri;

  final parts = uri.split('/').takeWhile((value) => value != 'src');
  final packageUri = '${parts.join('/')}/${parts.last}.dart';
  return packageUri;
}

/// Returns the relative import URI from a file to an imported file.
/// e.g. `lib/src/foo.dart` -> `lib/src/bar.dart` -> `../bar.dart`
String getRelativeImportUri(String imported, String file) {
  final importedParts = imported.split('/');
  final fileParts = file.split('/');

  final commonParts = <String>[];
  for (var i = 0; i < importedParts.length; i++) {
    if (importedParts[i] != fileParts[i]) break;
    commonParts.add(importedParts[i]);
  }

  final relativeParts = <String>[];
  for (var i = 1; i < fileParts.length - commonParts.length; i++) {
    relativeParts.add('..');
  }

  final importedRelativeParts = importedParts.skip(commonParts.length);
  relativeParts.addAll(importedRelativeParts);

  final packageUri = relativeParts.join('/');
  return packageUri;
}

/// Returns the relative path from a package URI.
/// e.g. `package:foo/src/bar.dart` -> `lib/src/bar.dart`
String getRelativePathFromPackageUri(Uri uri) {
  print('uri: $uri');
  final packageUri = uri.toString();
  final parts = packageUri.split('/');

  // TODO This is a quite naive implementation.
  final relativePath = [
    'lib',
    ...parts.skip(1),
  ].join('/');
  return relativePath;
}
