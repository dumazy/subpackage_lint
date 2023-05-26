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

