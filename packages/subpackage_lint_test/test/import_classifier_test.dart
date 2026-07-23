import 'package:subpackage_lint/src/import_classifier.dart';
import 'package:subpackage_lint/src/util/path_util.dart';
import 'package:test/test.dart';

/// A subpackage rooted at `/pkg/lib/<name>`.
SubpackageInfo sub(String name) => (name: name, path: '/pkg/lib/$name');

void main() {
  group('classifyResolvedImport', () {
    final feature = sub('feature');
    final other = sub('other');

    test('allows a relative import between two non-subpackage files', () {
      // Regression: `lib/domain/extra_field.dart` importing
      // `extra_field_value.dart` — neither file is in a subpackage, so there is
      // no boundary and the relative import must be allowed.
      expect(
        classifyResolvedImport(
          isPackageImport: false,
          targetIsBarrel: false,
          uriHasSrcSegment: false,
          sourceIsWithinSrc: false,
          sourceSubpackage: null,
          targetSubpackage: null,
        ),
        isNull,
      );
    });

    test('allows a relative import from a subpackage to a plain lib file', () {
      expect(
        classifyResolvedImport(
          isPackageImport: false,
          targetIsBarrel: false,
          uriHasSrcSegment: false,
          sourceIsWithinSrc: true,
          sourceSubpackage: feature,
          targetSubpackage: null,
        ),
        isNull,
      );
    });

    test('flags a relative import into another subpackage', () {
      final result = classifyResolvedImport(
        isPackageImport: false,
        targetIsBarrel: false,
        uriHasSrcSegment: false,
        sourceIsWithinSrc: true,
        sourceSubpackage: feature,
        targetSubpackage: other,
      );
      expect(
        result?.violation,
        SubpackageViolation.relativeImportFromOtherSubpackage,
      );
    });

    test('flags a package: import into another subpackage src file', () {
      final result = classifyResolvedImport(
        isPackageImport: true,
        targetIsBarrel: false,
        uriHasSrcSegment: true,
        sourceIsWithinSrc: true,
        sourceSubpackage: feature,
        targetSubpackage: other,
      );
      expect(
        result?.violation,
        SubpackageViolation.srcImportFromOtherSubpackage,
      );
    });

    test('allows a package: barrel import of another subpackage', () {
      expect(
        classifyResolvedImport(
          isPackageImport: true,
          targetIsBarrel: true,
          uriHasSrcSegment: false,
          sourceIsWithinSrc: true,
          sourceSubpackage: feature,
          targetSubpackage: other,
        ),
        isNull,
      );
    });

    group('same subpackage', () {
      test('flags importing its own barrel', () {
        final result = classifyResolvedImport(
          isPackageImport: false,
          targetIsBarrel: true,
          uriHasSrcSegment: false,
          sourceIsWithinSrc: true,
          sourceSubpackage: feature,
          targetSubpackage: feature,
        );
        expect(result?.violation, SubpackageViolation.ownSubpackageImport);
      });

      test('flags a package: import of a sibling file', () {
        final result = classifyResolvedImport(
          isPackageImport: true,
          targetIsBarrel: false,
          uriHasSrcSegment: true,
          sourceIsWithinSrc: true,
          sourceSubpackage: feature,
          targetSubpackage: feature,
        );
        expect(
          result?.violation,
          SubpackageViolation.preferRelativeFromSameSubpackage,
        );
      });

      test('flags a relative import routed through src from inside src', () {
        final result = classifyResolvedImport(
          isPackageImport: false,
          targetIsBarrel: false,
          uriHasSrcSegment: true,
          sourceIsWithinSrc: true,
          sourceSubpackage: feature,
          targetSubpackage: feature,
        );
        expect(
          result?.violation,
          SubpackageViolation.srcImportFromSameSubpackage,
        );
      });

      test('allows a src-routed import from a file above src', () {
        // A public file next to the barrel has no `src`-free alternative.
        expect(
          classifyResolvedImport(
            isPackageImport: false,
            targetIsBarrel: false,
            uriHasSrcSegment: true,
            sourceIsWithinSrc: false,
            sourceSubpackage: feature,
            targetSubpackage: feature,
          ),
          isNull,
        );
      });

      test('allows a plain relative import between two src files', () {
        expect(
          classifyResolvedImport(
            isPackageImport: false,
            targetIsBarrel: false,
            uriHasSrcSegment: false,
            sourceIsWithinSrc: true,
            sourceSubpackage: feature,
            targetSubpackage: feature,
          ),
          isNull,
        );
      });
    });
  });
}
