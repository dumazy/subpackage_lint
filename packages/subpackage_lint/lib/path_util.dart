String getPackageUriForAbsoluteImport(String uri) {
  if (!uri.contains('src')) return uri;

  final parts = uri.split('/').takeWhile((value) => value != 'src');
  final packageUri = parts.join('/') + '/' + parts.last + '.dart';
  return packageUri;
}

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
