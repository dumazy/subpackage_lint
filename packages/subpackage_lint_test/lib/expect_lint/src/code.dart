// expect_lint: avoid_src_import_from_other_subpackage
import '../../feature/src/code.dart';

// expect_lint: avoid_src_import_from_same_package
import '../src/other.dart';

// expect_lint: avoid_package_import_for_same_package
import 'package:tests/expect_lint/expect_lint.dart';

void main() {
  exampleFunction();
  otherExample();
  moreExamples();
}
