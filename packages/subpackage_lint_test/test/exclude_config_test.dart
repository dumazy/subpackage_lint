import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:subpackage_lint/src/exclude_config.dart';
import 'package:test/test.dart';

void main() {
  group('ExcludeConfig.fromPatterns.excludes', () {
    const root = '/pkg';
    String file(String rel) => p.join(root, rel);

    test('is false when no patterns are configured', () {
      final config = ExcludeConfig.fromPatterns(const []);
      expect(config.excludes(file('test/foo_test.dart'), root), isFalse);
    });

    test('matches files under a directory glob', () {
      final config = ExcludeConfig.fromPatterns(['test/**']);
      expect(config.excludes(file('test/foo_test.dart'), root), isTrue);
      expect(config.excludes(file('test/sub/bar_test.dart'), root), isTrue);
    });

    test('does not match a same-named directory deeper in the tree', () {
      final config = ExcludeConfig.fromPatterns(['test/**']);
      // `lib/test/...` must not match a root-anchored `test/**`.
      expect(config.excludes(file('lib/test/x.dart'), root), isFalse);
    });

    test('matches a suffix glob anywhere in the tree', () {
      final config = ExcludeConfig.fromPatterns(['**/*.g.dart']);
      expect(config.excludes(file('lib/model/user.g.dart'), root), isTrue);
      expect(config.excludes(file('lib/model/user.dart'), root), isFalse);
    });

    test('does not exclude a regular lib file', () {
      final config = ExcludeConfig.fromPatterns(['test/**', '**/*.g.dart']);
      expect(config.excludes(file('lib/feature/src/code.dart'), root), isFalse);
    });
  });

  group('ExcludeConfig.forPackage', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('subpackage_lint_cfg');
      ExcludeConfig.clearCache();
    });

    tearDown(() => dir.deleteSync(recursive: true));

    void writeOptions(String relative, String content) {
      final file = File(p.join(dir.path, relative));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    test('reads a top-level subpackage_lint: exclude section', () {
      writeOptions('analysis_options.yaml', '''
subpackage_lint:
  exclude:
    - test/**
''');
      final config = ExcludeConfig.forPackage(dir.path);
      expect(
        config.excludes(p.join(dir.path, 'test', 'a_test.dart'), dir.path),
        isTrue,
      );
      expect(
        config.excludes(p.join(dir.path, 'lib', 'a.dart'), dir.path),
        isFalse,
      );
    });

    test('is empty when there is no config file', () {
      final config = ExcludeConfig.forPackage(dir.path);
      expect(config.isEmpty, isTrue);
    });

    test('is empty when the section is absent', () {
      writeOptions('analysis_options.yaml', 'linter:\n  rules:\n');
      expect(ExcludeConfig.forPackage(dir.path).isEmpty, isTrue);
    });

    test('follows a relative include to a shared options file', () {
      // Mirrors a monorepo: the app options include a shared root that holds
      // the exclude section.
      writeOptions('shared/analysis_options.yaml', '''
subpackage_lint:
  exclude:
    - test/**
''');
      writeOptions('app/analysis_options.yaml', '''
include: ../shared/analysis_options.yaml
''');
      final appRoot = p.join(dir.path, 'app');
      final config = ExcludeConfig.forPackage(appRoot);
      expect(
        config.excludes(p.join(appRoot, 'test', 'a_test.dart'), appRoot),
        isTrue,
      );
    });

    test('re-reads after the options file changes', () {
      writeOptions('analysis_options.yaml', 'subpackage_lint:\n  exclude: []\n');
      expect(ExcludeConfig.forPackage(dir.path).isEmpty, isTrue);

      // Sleep briefly so the modified timestamp is guaranteed to advance.
      sleep(const Duration(milliseconds: 10));
      writeOptions(
        'analysis_options.yaml',
        'subpackage_lint:\n  exclude:\n    - test/**\n',
      );
      expect(ExcludeConfig.forPackage(dir.path).isEmpty, isFalse);
    });
  });
}
