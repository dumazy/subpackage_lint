// import 'package:example/feature/feature.dart'; // invalid package import
// import 'package:example/feature/src/code.dart'; // invalid absolute import
// import 'package:example/other_feature/src/private.dart'; // invalid src import of another feature
// import 'package:example/other_feature/src/public.dart'; // invalid src import of another feature
// import '../src/code.dart'; // invalid relative import

import 'package:example/other_feature/other_feature.dart'; // correct, no src import
import 'package:example/no_subpackage/without_subpackage.dart'; // correct, no subpackage
import 'code.dart'; // correct

void anotherExampleFunction() {
  exampleFunction();
  publicFunction();
  // privateFunction();
  withoutSubpackageFunction();
}
