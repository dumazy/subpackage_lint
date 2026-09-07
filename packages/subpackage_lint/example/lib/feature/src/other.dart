// This file lives inside the `feature` subpackage (under its `src/`).

import 'code.dart'; // ✅ sibling in the same subpackage
import 'package:example/other_feature/other_feature.dart'; // ✅ another subpackage's barrel
import 'package:example/no_subpackage/without_subpackage.dart'; // ✅ plain file, any style is fine

// Uncomment any of these to see the rule fire:
// import 'package:example/feature/feature.dart'; // ❌ avoid_own_subpackage_import
// import '../feature.dart'; // ❌ avoid_own_subpackage_import
// import 'package:example/feature/src/code.dart'; // ❌ prefer_relative_import_from_same_subpackage
// import '../src/code.dart'; // ❌ avoid_src_import_from_same_subpackage
// import '../../other_feature/other_feature.dart'; // ❌ avoid_relative_subpackage_import
// import '../../other_feature/src/public.dart'; // ❌ avoid_relative_import_from_other_subpackage
// import 'package:example/other_feature/src/private.dart'; // ❌ avoid_src_import_from_other_subpackage

void anotherExampleFunction() {
  exampleFunction();
  publicFunction();
  withoutSubpackageFunction();
}
