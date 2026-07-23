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
      final info =
          getSubpackageInfo(fixture('lib/feature/src/deep/nested.dart'));
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
      expect(isWithinSrc(feature, fixture('lib/feature/src/code.dart')), isTrue);
    });

    test('is true for a deeply nested src file', () {
      expect(
        isWithinSrc(feature, fixture('lib/feature/src/deep/nested.dart')),
        isTrue,
      );
    });

    test('is false for the barrel file (above src)', () {
      expect(isWithinSrc(feature, fixture('lib/feature/feature.dart')), isFalse);
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
}
