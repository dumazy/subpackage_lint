/// Lint rules that keep imports honest about a `lib/` structured into
/// subpackages: a public barrel file over a private `src/` folder.
///
/// This is an analyzer plugin. It is enabled under `plugins:` in
/// `analysis_options.yaml`, not imported from Dart code; see the README. The
/// analysis server loads the plugin through `lib/main.dart`. This library only
/// exposes the plugin class for tooling and tests.
library;

export 'src/plugin.dart' show SubpackageLintPlugin;
