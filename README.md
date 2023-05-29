# Kerekewere

[![pub package](https://img.shields.io/pub/v/kerekewere.svg)](https://pub.dev/packages/kerekewere)

A custom lint package for Dart.

## Features

Warns about using src/ in import paths for subpackages.

## Getting started

Add the following to your `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_lint: 
  kerekewere:
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
