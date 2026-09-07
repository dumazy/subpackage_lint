// This file is not part of any subpackage, so it reaches `feature` only
// through its barrel file.

import 'package:example/feature/feature.dart'; // ✅

// import 'feature/feature.dart'; // ❌ avoid_relative_subpackage_import
// import 'package:example/feature/src/code.dart'; // ❌ avoid_src_import_from_other_subpackage

void main() {
  exampleFunction();
}
