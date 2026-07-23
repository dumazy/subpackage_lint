import 'dart:io';

import 'package:path/path.dart' as p;

/// Information about a discovered subpackage.
///
/// A subpackage is a directory inside `lib` that contains both a `src`
/// directory and a barrel library file named after the directory itself, e.g.
/// `lib/feature/feature.dart` alongside `lib/feature/src/`.
typedef SubpackageInfo = ({String name, String path});

/// Finds the subpackage that owns the file at [absolutePath].
///
/// Walks up the directory tree from the file until the enclosing `lib`
/// directory, returning the first directory that qualifies as a subpackage
/// (see [SubpackageInfo]). Returns `null` when the file is not inside a
/// subpackage.
SubpackageInfo? getSubpackageInfo(String absolutePath) {
  final pathParts = p.split(absolutePath);
  final libIndex = pathParts.indexOf('lib');

  // Only files inside a `lib` directory can belong to a subpackage.
  if (libIndex == -1) return null;
  final libPath = p.joinAll(pathParts.take(libIndex + 1));

  var currentDir = p.dirname(absolutePath);
  while (
      currentDir.length >= libPath.length && p.isWithin(libPath, currentDir)) {
    if (_isSubpackageDir(currentDir)) {
      return (name: p.basename(currentDir), path: currentDir);
    }

    final parentDir = p.dirname(currentDir);
    if (parentDir == currentDir) break;
    currentDir = parentDir;
  }

  return null;
}

/// Whether [absolutePath] lives inside the `src` directory of [subpackage].
///
/// Only files under `src` can reach a sibling `src` file with a `src`-free
/// relative path, so this gates the `avoid_src_import_from_same_subpackage`
/// rule: a file *above* `src` (e.g. a public file next to the barrel) has no
/// way to import into `src` without naming it.
bool isWithinSrc(SubpackageInfo subpackage, String absolutePath) =>
    p.isWithin(p.join(subpackage.path, 'src'), absolutePath);

/// The minimal POSIX-style relative import URI from [fromFile] to [targetPath].
///
/// e.g. from `.../feature/src/other.dart` to `.../feature/src/code.dart`
/// yields `code.dart` — never `../src/code.dart`.
String relativeImportUri({
  required String fromFile,
  required String targetPath,
}) {
  final relative = p.relative(targetPath, from: p.dirname(fromFile));
  // Ensure POSIX separators regardless of host platform.
  return p.split(relative).join('/');
}

/// Whether [absolutePath] points to a subpackage's barrel library file.
///
/// e.g. `lib/feature/feature.dart` when `lib/feature/src/` exists.
bool isSubpackageBarrel(String absolutePath) {
  final parentDir = p.dirname(absolutePath);
  if (!_isSubpackageDir(parentDir)) return false;
  return absolutePath == _barrelPathFor(parentDir);
}

/// Whether [dir] qualifies as a subpackage directory: it contains both a `src`
/// directory and a barrel file named after the directory.
bool _isSubpackageDir(String dir) {
  final hasSrcFolder = Directory(p.join(dir, 'src')).existsSync();
  if (!hasSrcFolder) return false;
  return File(_barrelPathFor(dir)).existsSync();
}

String _barrelPathFor(String dir) => p.join(dir, '${p.basename(dir)}.dart');
