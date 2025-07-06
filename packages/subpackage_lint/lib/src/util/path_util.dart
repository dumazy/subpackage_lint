import 'dart:io';

import 'package:path/path.dart' as p;

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
  final packageUri = uri.toString();
  final parts = packageUri.split('/');

  // TODO This is a quite naive implementation.
  final relativePath = [
    'lib',
    ...parts.skip(1),
  ].join('/');
  return relativePath;
}

/// A record to hold information about a discovered subpackage.
typedef SubpackageInfo = ({String name, String path});

/// Finds the subpackage directory for a given file path based on the new rules.
/// Returns a record containing the name and path of the subpackage, or null if not found.
SubpackageInfo? getSubpackageInfo(String absolutePath) {
  var currentDir = p.dirname(absolutePath);
  final pathParts = p.split(absolutePath);
  final libIndex = pathParts.indexOf('lib');

  // Ensure we are inside the 'lib' directory.
  if (libIndex == -1) {
    return null;
  }
  final libPath = p.joinAll(pathParts.take(libIndex + 1));

  // Traverse up the directory tree until we hit the 'lib' directory.
  while (
      currentDir.length >= libPath.length && currentDir.startsWith(libPath)) {
    final subpackageName = p.basename(currentDir);
    final hasSrcFolder = Directory(p.join(currentDir, 'src')).existsSync();
    final hasLibraryFile =
        File(p.join(currentDir, '$subpackageName.dart')).existsSync();

    if (hasSrcFolder && hasLibraryFile) {
      // We found a directory that matches the subpackage criteria.
      return (name: subpackageName, path: currentDir);
    }

    // Move up one directory.
    final parentDir = p.dirname(currentDir);
    // Stop if we've reached the top or are about to exit the 'lib' directory.
    if (parentDir == currentDir) break;
    currentDir = parentDir;
  }

  return null;
}

/// Checks if the given absolute path points to a subpackage's barrel file.
bool isSubpackage(String absolutePath) {
  final parentDir = p.dirname(absolutePath);
  final hasSrcFolder = Directory(p.join(parentDir, 'src')).existsSync();
  if (!hasSrcFolder) return false;
  final expectedPathLibraryFile = '$parentDir/${p.basename(parentDir)}.dart';
  return expectedPathLibraryFile == absolutePath;
}
