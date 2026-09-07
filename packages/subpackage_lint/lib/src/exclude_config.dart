import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The file exclusion configured for the subpackage rules.
///
/// The rules are read from a package's `analysis_options.yaml` under a
/// top-level `subpackage_lint` section (the analyzer's plugin config only
/// exposes the `diagnostics:` block, so this section is parsed by the plugin
/// itself):
///
/// ```yaml
/// subpackage_lint:
///   exclude:
///     - test/**
///     - "**/*.g.dart"
/// ```
///
/// A file is excluded when its path — made relative to the package root —
/// matches any configured glob. Relative `include:` directives are followed, so
/// the section may live in a shared options file (e.g. a monorepo root).
class ExcludeConfig {
  ExcludeConfig(this._globs);

  /// Builds a config from raw glob [patterns] (matched with POSIX semantics).
  ExcludeConfig.fromPatterns(Iterable<String> patterns)
    : this([for (final pattern in patterns) Glob(pattern, context: p.posix)]);

  final List<Glob> _globs;

  /// Whether any exclusion is configured.
  bool get isEmpty => _globs.isEmpty;

  static final Map<String, _CacheEntry> _cache = {};

  /// The config for the package rooted at [packageRootPath], read from
  /// `<packageRootPath>/analysis_options.yaml` and cached. The cache is
  /// refreshed when that options file changes on disk.
  factory ExcludeConfig.forPackage(String packageRootPath) {
    final optionsPath = p.join(packageRootPath, 'analysis_options.yaml');
    final stamp = _modifiedStamp(optionsPath);

    final cached = _cache[packageRootPath];
    if (cached != null && cached.stamp == stamp) return cached.config;

    final config = ExcludeConfig.fromPatterns(
      _readPatterns(optionsPath, <String>{}),
    );
    _cache[packageRootPath] = _CacheEntry(stamp, config);
    return config;
  }

  /// Clears the in-memory cache. Intended for tests.
  static void clearCache() => _cache.clear();

  /// Whether [absolutePath] is excluded, matching each glob against the path
  /// relative to [packageRootPath] (using POSIX separators).
  bool excludes(String absolutePath, String packageRootPath) {
    if (_globs.isEmpty) return false;
    final relative = p.posix.joinAll(
      p.split(p.relative(absolutePath, from: packageRootPath)),
    );
    return _globs.any((glob) => glob.matches(relative));
  }

  /// A monotonic stamp for the options file's last-modified time, or `-1` when
  /// it does not exist. Uses a single `stat` call.
  static int _modifiedStamp(String path) {
    final stat = File(path).statSync();
    if (stat.type == FileSystemEntityType.notFound) return -1;
    return stat.modified.microsecondsSinceEpoch;
  }

  /// Collects `subpackage_lint: exclude:` entries from the options file at
  /// [optionsPath] and any relatively-included options files. [seen] guards
  /// against include cycles.
  static List<String> _readPatterns(String optionsPath, Set<String> seen) {
    final normalized = p.normalize(optionsPath);
    if (!seen.add(normalized)) return const [];

    final file = File(normalized);
    if (!file.existsSync()) return const [];

    final YamlNode doc;
    try {
      doc = loadYamlNode(file.readAsStringSync());
    } on YamlException {
      return const [];
    }
    if (doc is! YamlMap) return const [];

    final patterns = <String>[];

    final section = doc['subpackage_lint'];
    if (section is YamlMap) {
      final exclude = section['exclude'];
      if (exclude is YamlList) {
        for (final entry in exclude) {
          if (entry is String) patterns.add(entry);
        }
      }
    }

    // Follow relative `include:` directives (a single string or a list).
    // Package includes (e.g. `package:lints/recommended.yaml`) can't carry user
    // config and are skipped.
    for (final include in _includes(doc['include'])) {
      if (include.startsWith('package:')) continue;
      final includedPath = p.join(p.dirname(normalized), include);
      patterns.addAll(_readPatterns(includedPath, seen));
    }

    return patterns;
  }

  static List<String> _includes(Object? include) {
    if (include is String) return [include];
    if (include is YamlList) {
      return [
        for (final entry in include)
          if (entry is String) entry,
      ];
    }
    return const [];
  }
}

class _CacheEntry {
  _CacheEntry(this.stamp, this.config);

  final int stamp;
  final ExcludeConfig config;
}
