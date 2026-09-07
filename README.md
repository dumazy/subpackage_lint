# subpackage_lint

[![pub package](https://img.shields.io/pub/v/subpackage_lint.svg)](https://pub.dev/packages/subpackage_lint)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/K3K3NJK6V)

**Structure `lib/` into subpackages — each a public barrel file over a private
`src/` folder — and let the linter keep every import honest about that shape.**

subpackage_lint is one convention plus the rules that enforce it:

- **A subpackage** is a directory with a barrel library that exports its public
  API (`my_subpackage/my_subpackage.dart`) and a `src/` folder holding
  everything else.
- **`src/` is private.** Other subpackages reach it only through the barrel.
- **Imports follow the boundary:** relative *within* a subpackage, `package:`
  (through the barrel) *across* subpackages.

That's the whole idea. Each of the six [rules](#rules) is just a specific way to
break it — caught in your IDE and on `dart analyze`, most with a quick fix.

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

```dart
// my_subpackage/my_subpackage.dart

/// Here's a description of what this subpackage does.
/// This comment will be visible in your IDE when hovering over the import of this library file.
library;

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

> **Requires Dart 3.10 or later.** As of version 2.0.0 `subpackage_lint` is a
> native analyzer plugin built on the
> [analyzer plugin system](https://dart.dev/tools/analyzer-plugins). It no
> longer depends on `custom_lint`.

Enable the plugin and the rules you want in your `analysis_options.yaml`:

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

That is the only change you need. **Do not add `subpackage_lint` to your
`pubspec.yaml`.** The analysis server fetches and compiles the plugin in its
own isolated package, so it never competes with your project's dependencies
(`build_runner`, `freezed`, `json_serializable`, ...) and there is no
`analyzer` version to reconcile.

A few things to know:

- The `version:` line is required. Without it (or a `path:`) the analyzer
  silently skips the plugin and the rules never run.
- `plugins:` is only read from the `analysis_options.yaml` at the root of your
  package (or of your pub workspace, if you use one). The analyzer reports
  `plugins_in_inner_options` if you put it anywhere else.
- Every rule is off by default; list the ones you want under `diagnostics:`.

The rules run in your IDE and on the command line via `dart analyze`. Most
violations come with a quick fix in the IDE.

> **Flutter projects:** the plugin works with the Dart SDK bundled with Flutter,
> but prefer `dart analyze` over `flutter analyze` on the command line and in
> CI. `flutter analyze` exits as soon as the analysis server reports its own
> analysis complete, which is a few seconds before plugin diagnostics arrive, so
> it silently misses them. `dart analyze` waits for plugins.

## Rules

| Rule | Reports when… |
| --- | --- |
| `avoid_own_subpackage_import` | A file imports its own subpackage's barrel file instead of using relative imports. |
| `avoid_relative_subpackage_import` | A subpackage's barrel file is imported with a relative import instead of a `package:` import. |
| `prefer_relative_import_from_same_subpackage` | A file uses a `package:` import for another file in the same subpackage. |
| `avoid_src_import_from_same_subpackage` | A relative import within a subpackage reaches through its `src` directory. |
| `avoid_relative_import_from_other_subpackage` | A file in another subpackage is imported with a relative import. |
| `avoid_src_import_from_other_subpackage` | A file from another subpackage's `src` directory is imported directly instead of its barrel file. |

## Configuring rules

Each rule is configured individually under the `diagnostics:` key. You can
disable a rule or change its severity:

```yaml
plugins:
  subpackage_lint:
    version: ^2.0.0
    diagnostics:
      avoid_src_import_from_other_subpackage: error # info | warning | error
      avoid_relative_import_from_other_subpackage: true # default severity (warning)
      prefer_relative_import_from_same_subpackage: false # disabled
```

`analyzer: errors:` overrides do **not** apply to plugin diagnostics, so this
block is the place to change a rule's severity.

## Suppressing a diagnostic

Plugin diagnostics are suppressed with the usual ignore comments, prefixed with
the plugin name:

```dart
// ignore: subpackage_lint/avoid_src_import_from_other_subpackage
import 'package:my_app/my_subpackage/src/some_public_file.dart';
```

```dart
// ignore_for_file: subpackage_lint/avoid_src_import_from_other_subpackage
```

## Excluding files

To exclude files from **only** the subpackage rules — while every other lint
still applies — add an `exclude:` list of [globs][glob] under a top-level
`subpackage_lint:` section. This is useful for tests, which often need to import
a subpackage's `src` directly:

```yaml
plugins:
  subpackage_lint:
    version: ^2.0.0
    diagnostics:
      avoid_src_import_from_other_subpackage: true

subpackage_lint:
  exclude:
    - test/**
    - "**/*.g.dart"
```

Globs are matched against each file's path relative to the package root. The
section is read from your `analysis_options.yaml`, following relative
`include:` directives — so in a monorepo you can put it in a shared options file
that each package includes.

To instead exclude files from **all** analysis (this plugin's rules *and* every
other lint), use the standard analyzer `exclude:` option:

```yaml
analyzer:
  exclude:
    - "**.g.dart"
    - "lib/my/excluded/directory/**"
```

> **Note:** The analyzer only reads `plugins:` from the root
> `analysis_options.yaml`, so a nested options file cannot enable, disable, or
> re-severity these rules, and `analyzer: errors:` does not apply to them. Use
> `diagnostics:` for severity, an
> [ignore comment](#suppressing-a-diagnostic) for a single import, and
> `subpackage_lint: exclude:` for whole files.

[glob]: https://pub.dev/packages/glob#syntax
