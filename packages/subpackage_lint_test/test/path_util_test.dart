import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:subpackage_lint/src/util/path_util.dart';
import 'package:test/test.dart';

/// Absolute path to a file inside `test/fixtures`.
String fixture(String relative) =>
    p.join(Directory.current.path, 'test', 'fixtures', relative);

void main() {
  group('getSubpackageInfo', () {
    test('returns the enclosing subpackage for a file in src', () {
      final info = getSubpackageInfo(fixture('lib/feature/src/code.dart'));
      expect(info, isNotNull);
      expect(info!.name, 'feature');
      expect(info.path, fixture('lib/feature'));
    });

    test('returns the subpackage for a deeply nested src file', () {
      final info = getSubpackageInfo(
        fixture('lib/feature/src/deep/nested.dart'),
      );
      expect(info?.name, 'feature');
    });

    test('returns the subpackage for the barrel file itself', () {
      final info = getSubpackageInfo(fixture('lib/feature/feature.dart'));
      expect(info?.name, 'feature');
    });

    test('returns null for a directory that is not a subpackage', () {
      // `plain_dir` has no `src/` folder and no matching barrel file.
      expect(getSubpackageInfo(fixture('lib/plain_dir/plain.dart')), isNull);
    });

    test('returns null for a top-level lib file', () {
      expect(getSubpackageInfo(fixture('lib/top_level.dart')), isNull);
    });

    test('returns null for a path outside any lib directory', () {
      expect(getSubpackageInfo('/tmp/somewhere/foo.dart'), isNull);
    });
  });

  group('isWithinSrc', () {
    final feature = getSubpackageInfo(fixture('lib/feature/src/code.dart'))!;

    test('is true for a file directly in src', () {
      expect(
        isWithinSrc(feature, fixture('lib/feature/src/code.dart')),
        isTrue,
      );
    });

    test('is true for a deeply nested src file', () {
      expect(
        isWithinSrc(feature, fixture('lib/feature/src/deep/nested.dart')),
        isTrue,
      );
    });

    test('is false for the barrel file (above src)', () {
      expect(
        isWithinSrc(feature, fixture('lib/feature/feature.dart')),
        isFalse,
      );
    });

    test('is false for a public file next to the barrel (above src)', () {
      // Regression: such a file has no `src`-free way to import into `src`, so
      // it must not be flagged by avoid_src_import_from_same_subpackage.
      expect(isWithinSrc(feature, fixture('lib/feature/helper.dart')), isFalse);
    });
  });

  group('relativeImportUri', () {
    test('collapses a sibling src file to a bare name', () {
      // Regression: the old fix stripped 'src' textually, turning
      // '../src/code.dart' into '../code.dart' (wrong dir). It must resolve to
      // 'code.dart'.
      expect(
        relativeImportUri(
          fromFile: fixture('lib/feature/src/other.dart'),
          targetPath: fixture('lib/feature/src/code.dart'),
        ),
        'code.dart',
      );
    });

    test('walks between sibling folders without naming src', () {
      expect(
        relativeImportUri(
          fromFile: fixture('lib/feature/src/view/example_view.dart'),
          targetPath: fixture('lib/feature/src/domain/example_domain.dart'),
        ),
        '../domain/example_domain.dart',
      );
    });

    test('walks up out of a nested folder', () {
      expect(
        relativeImportUri(
          fromFile: fixture('lib/feature/src/deep/nested.dart'),
          targetPath: fixture('lib/feature/src/code.dart'),
        ),
        '../code.dart',
      );
    });
  });

  group('isSubpackageBarrel', () {
    test('is true for the barrel file', () {
      expect(isSubpackageBarrel(fixture('lib/feature/feature.dart')), isTrue);
    });

    test('is false for a src file', () {
      expect(isSubpackageBarrel(fixture('lib/feature/src/code.dart')), isFalse);
    });

    test('is false for a non-subpackage file', () {
      expect(isSubpackageBarrel(fixture('lib/plain_dir/plain.dart')), isFalse);
    });

    test('is false for a top-level lib file', () {
      expect(isSubpackageBarrel(fixture('lib/top_level.dart')), isFalse);
    });
  });

  group('barrelPackageUri', () {
    test('maps a src file to its subpackage barrel', () {
      expect(
        barrelPackageUri(
          targetLibraryUri: Uri.parse('package:fixtures/feature/src/code.dart'),
          targetPath: fixture('lib/feature/src/code.dart'),
        ),
        Uri.parse('package:fixtures/feature/feature.dart'),
      );
    });

    test('maps a deeply nested src file to its subpackage barrel', () {
      expect(
        barrelPackageUri(
          targetLibraryUri: Uri.parse(
            'package:fixtures/feature/src/deep/nested.dart',
          ),
          targetPath: fixture('lib/feature/src/deep/nested.dart'),
        ),
        Uri.parse('package:fixtures/feature/feature.dart'),
      );
    });

    test('maps the barrel to itself', () {
      expect(
        barrelPackageUri(
          targetLibraryUri: Uri.parse('package:fixtures/feature/feature.dart'),
          targetPath: fixture('lib/feature/feature.dart'),
        ),
        Uri.parse('package:fixtures/feature/feature.dart'),
      );
    });

    test('is null for a file outside any subpackage', () {
      expect(
        barrelPackageUri(
          targetLibraryUri: Uri.parse('package:fixtures/plain_dir/plain.dart'),
          targetPath: fixture('lib/plain_dir/plain.dart'),
        ),
        isNull,
      );
    });

    test('is null for a non-package URI (e.g. a test file)', () {
      expect(
        barrelPackageUri(
          targetLibraryUri: Uri.file(fixture('lib/feature/src/code.dart')),
          targetPath: fixture('lib/feature/src/code.dart'),
        ),
        isNull,
      );
    });
  });

  group('subpackage detection cache', () {
    late Directory dir;
    late String barrel;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('subpackage_lint_cache');
      // A `feature` dir with a barrel file but (initially) no `src` folder, so
      // it is not yet a subpackage.
      final feature = Directory(p.join(dir.path, 'lib', 'feature'))
        ..createSync(recursive: true);
      barrel = p.join(feature.path, 'feature.dart');
      File(barrel).writeAsStringSync('');
      resetSubpackageDetectionCache();
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
      resetSubpackageDetectionCache();
    });

    test('caches the result until explicitly reset', () {
      expect(isSubpackageBarrel(barrel), isFalse);

      // Turn it into a real subpackage on disk; the cached negative result is
      // intentionally kept (stable within an analysis session).
      Directory(p.join(dir.path, 'lib', 'feature', 'src')).createSync();
      expect(isSubpackageBarrel(barrel), isFalse, reason: 'cached');

      // A reset (isolate restart, in production) picks up the change.
      resetSubpackageDetectionCache();
      expect(isSubpackageBarrel(barrel), isTrue);
    });
  });
}
