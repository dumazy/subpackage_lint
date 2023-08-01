// This is an excluded example.
// This file should not be linted.

// This should trigger lint 'avoid_src_import_from_other_subpackage' if not excluded.
import 'package:tests/feature/src/code.dart';

void excludedExample() {
  exampleFunction();
}
