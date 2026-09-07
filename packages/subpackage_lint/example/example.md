# subpackage_lint example

This folder is a tiny Dart package with two subpackages, one plain directory,
and all six rules enabled. It shows the convention the rules enforce and what
each rule catches.

## 1. Enable the plugin

`analysis_options.yaml` is the only file you touch. Nothing is added to
`pubspec.yaml`; the analysis server fetches and builds the plugin on its own.

```yaml
plugins:
  subpackage_lint:
    version: ^2.0.0
    diagnostics:
      avoid_own_subpackage_import: true
      avoid_relative_subpackage_import: true
      prefer_relative_import_from_same_subpackage: true
      avoid_src_import_from_same_subpackage: true
      avoid_relative_import_from_other_subpackage: true
      avoid_src_import_from_other_subpackage: true
```

## 2. Lay out `lib/` as subpackages

A subpackage is a directory with a barrel file named after it and a private
`src/` folder. Everything else in `lib/` is ordinary and left alone.

```
lib/
├── main.dart
├── feature/
│   ├── feature.dart              # barrel: exports src/code.dart
│   └── src/
│       ├── code.dart
│       └── other.dart
├── other_feature/
│   ├── other_feature.dart        # barrel: exports src/public.dart
│   └── src/
│       ├── public.dart
│       └── private.dart          # not exported: private to other_feature
└── no_subpackage/
    └── without_subpackage.dart   # plain file, no subpackage rules apply
```

The barrel is the subpackage's public API:

```dart
// lib/feature/feature.dart

/// The `feature` subpackage. This doc comment shows up in the IDE when
/// hovering the import elsewhere in the project.
library;

export 'src/code.dart';
```

## 3. Inside a subpackage: relative imports, never through `src`

`lib/feature/src/other.dart` lives inside `feature`. Sibling files are reached
with plain relative paths; other subpackages through their barrel with a
`package:` import.

```dart
// lib/feature/src/other.dart

import 'code.dart'; // ✅ sibling in the same subpackage
import 'package:example/other_feature/other_feature.dart'; // ✅ another subpackage's barrel
import 'package:example/no_subpackage/without_subpackage.dart'; // ✅ plain file, any style is fine

import 'package:example/feature/feature.dart'; // ❌ avoid_own_subpackage_import
import '../feature.dart'; // ❌ avoid_own_subpackage_import
import 'package:example/feature/src/code.dart'; // ❌ prefer_relative_import_from_same_subpackage
import '../src/code.dart'; // ❌ avoid_src_import_from_same_subpackage
import '../../other_feature/other_feature.dart'; // ❌ avoid_relative_subpackage_import
import '../../other_feature/src/public.dart'; // ❌ avoid_relative_import_from_other_subpackage
import 'package:example/other_feature/src/private.dart'; // ❌ avoid_src_import_from_other_subpackage
```

## 4. Outside a subpackage: import the barrel

`lib/main.dart` is not part of any subpackage. It reaches `feature` only
through the barrel, so `feature/src` can change freely.

```dart
// lib/main.dart

import 'package:example/feature/feature.dart'; // ✅

// import 'feature/feature.dart';                    // ❌ avoid_relative_subpackage_import
// import 'package:example/feature/src/code.dart';   // ❌ avoid_src_import_from_other_subpackage

void main() {
  exampleFunction();
}
```

## 5. Run it

```sh
dart analyze
```

Every ❌ line above is reported as a warning, and each one has a quick fix in
the IDE that rewrites the import. Uncomment the bad imports in
`lib/feature/src/other.dart` in this folder to see them fire.

To silence a single import, prefix the rule with the plugin name:

```dart
// ignore: subpackage_lint/avoid_src_import_from_other_subpackage
import 'package:example/other_feature/src/private.dart';
```

To keep whole files out of these rules (tests often need `src`), add globs
under a top-level `subpackage_lint:` key in `analysis_options.yaml`:

```yaml
subpackage_lint:
  exclude:
    - test/**
```
