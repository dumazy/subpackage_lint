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

> **Requires Dart 3.10 or later.** As of version 2.0.0 `subpackage_lint` is a
> native analyzer plugin built on the
> [new analyzer plugin system](https://dart.dev/tools/analyzer-plugins). It no
> longer depends on `custom_lint`.
>
> The `analyzer` dependency is intentionally kept to a wide range so the plugin
> can share a project with codegen tools such as `build_runner`, `freezed`, and
> `json_serializable` that may pin an older `analyzer`. `pub` will pick the
> newest compatible analyzer for your project.

Add `subpackage_lint` to your dev dependencies:

```yaml
dev_dependencies:
  subpackage_lint: ^2.0.0
```

Then enable the plugin and the rules you want in your `analysis_options.yaml`:

```yaml
plugins:
  subpackage_lint:
    diagnostics:
      avoid_own_subpackage_import: true
      avoid_relative_subpackage_import: true
      prefer_relative_import_from_same_subpackage: true
      avoid_src_import_from_same_subpackage: true
      avoid_relative_import_from_other_subpackage: true
      avoid_src_import_from_other_subpackage: true
```

The rules run in your IDE and on the command line via `dart analyze` and
`flutter analyze`. Most violations come with a quick fix.

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
    diagnostics:
      avoid_src_import_from_other_subpackage: warning # info | warning | error
      prefer_relative_import_from_same_subpackage: false # disabled
```

## Excluding files

To exclude files from **only** the subpackage rules — while every other lint
still applies — add an `exclude:` list of [globs][glob] under a top-level
`subpackage_lint:` section. This is useful for tests, which often need to import
a subpackage's `src` directly:

```yaml
plugins:
  subpackage_lint:
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

> **Note:** The analyzer only reads a plugin's `diagnostics:` configuration from
> the root of an analysis context, so a nested `analysis_options.yaml`,
> `analyzer: errors:` overrides, and `// ignore` comments do not turn these
> rules off. The `subpackage_lint: exclude:` option above is the supported way
> to scope them.

[glob]: https://pub.dev/packages/glob#syntax
