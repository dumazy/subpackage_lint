# subpackage_lint

[![pub package](https://img.shields.io/pub/v/subpackage_lint.svg)](https://pub.dev/packages/subpackage_lint)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/K3K3NJK6V)

A set of lint rules to enforce best practices for subpackages.

## Philosophy

Subpackages or "lightweight packages" are a way of splitting up your code into separate modules without introducing the overhead of adding extra build tools or having to manage code in several places.

The idea is to group of one feature together and treat it like it would be a separate library, but without moving to another project and maintaining the flexibility of overriding the rule if necessary.

```
/my_subpackage
├── my_subpackage.dart
└── /src
    ├── /a_folder
    │   └── another_private_file.dart
    ├── a_private_file.dart
    └── some_public_file.dart
```

Within the code, for example in the `/lib` directory of your Dart app, you create a new directory which will contain everything of your subpackage.
Let's name this `my_subpackage` in this example.
Top-level within that directory you'll create a library file that contains all the exports of this package.
Exports are the files and classes you want to make publicly available.
This library file should have the same name as your directory, so you'll end up with the following naming convention: `/my_subpackage/my_subpackage.dart`

Considering the example above, this could be the content of the library file:

```
// my_subpackage/my_subpackage.dart


/// Here's a description of what this subpackage does
/// This comment will be visible in your IDE when hovering over the import of this library file.
library my_subpackage;

export 'src/some_public_file.dart'; // only export the public files or classes
```

### Imports

The golden rule is to avoid `/src/` anywhere in your imports.

#### Within the subpackage

Use relative imports within the src directory of the subpackage. If you see `src` somewhere in a relative import, it means you went too far.

```
// Good
import 'a_private_file.dart';

// Good
import '../some_public_file.dart';

// Bad
import '../src/a_private_file.dart';

// Bad
import 'package:my_app/my_subpackage/my_subpackage.dart';

// Bad
import 'package:my_app/my_subpackage/src/a_private_file.dart';

// Bad
import '../my_subpackage.dart';
```

#### Importing the subpackage

When using this subpackage somewhere else in your code, you should import the library file:

```
// Good: absolute import of library file
import 'package:my_app/my_subpackage/my_subpackage.dart';

// Bad: absolute import of src file
import 'package:my_app/my_subpackage/src/some_public_file.dart'

// Bad: relative import of src file
import '../../my_subpackage/src/some_public_file.dart';

// Not recommended: relative import of library file
import '../../my_subpackage/my_subpackage.dart';
```

This way of organizing your imports is not enforced by the framework and is a guideline that the developers should agree to. Luckily, there are these lint rules to help you.

## Getting started

Add the following to your `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_lint:
  subpackage_lint:
```

Add the following to the `analysis_options.yaml` file:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## Exclude files

To exclude files from being linted, add the following to the `analysis_options.yaml` file:

```yaml
custom_lint:
  rules:
    - avoid_src_import_from_other_subpackage:
      exclude:
        - "*_test.dart"
        - "*.g.dart"
    - avoid_src_import_from_same_package:
      exclude:
        - "*_test.dart"
    - avoid_package_import_for_same_package:
      exclude:
        - "*_test.dart"
```

Currently, you can only exclude files using glob patterns and not specify with absolute paths.
For example: `lib/my/path/*.g.dart` will not work.
