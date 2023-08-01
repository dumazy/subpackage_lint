import 'package:subpackage_lint/exclude/exclude.dart';
import 'package:test/test.dart';

void main() {
  group('Exclude matches', () {
    group('Wildcard with fixed suffix', () {
      final exclude = '**_test.dart';

      test('matches relative path', () {
        final path = 'example/path/exclude_test.dart';

        final result = exclude.matches(path);

        expect(result, isTrue);
      });

      test('does not match relative path with other suffix', () {
        final path = 'example/path/exclude.dart';

        final result = exclude.matches(path);

        expect(result, isFalse);
      });
    });

    group('Partial wildcard with suffix', () {
      test('matches relative path', () {
        final exclude = 'example/**_test.dart';
        final path = 'example/path/exclude_test.dart';

        final result = exclude.matches(path);

        expect(result, isTrue);
      });
    });

    group('Exact match', () {
      test('matches relative path', () {
        final exclude = 'example/path/exclude_test.dart';
        final path = 'example/path/exclude_test.dart';

        final result = exclude.matches(path);

        expect(result, isTrue);
      });
    });

    group('Directory with wildcard', () {
      test('matches relative path', () {
        final exclude = 'example/**';
        final path = 'example/path/exclude_test.dart';

        final result = exclude.matches(path);

        expect(result, isTrue);
      });
    });
  });
}
