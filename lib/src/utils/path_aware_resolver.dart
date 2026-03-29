// Author: Jiten Basnet
import 'dart:io';

import 'package:interact/interact.dart' hide Progress;
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';

/// Resolves the target feature name from:
/// 1. An explicit [argValue] passed directly (e.g. from a positional arg flag)
/// 2. The current working directory, if it is inside a known features folder
/// 3. An interactive [Select] prompt from registered features in simplex.yaml
/// 4. A free-form [Input] prompt as a last resort
String resolveFeatureName({
  required SimplexConfig config,
  required String projectRoot,
  String? argValue,
  bool interactive = true,
}) {
  // 1. Explicit value wins immediately
  if (argValue != null && argValue.trim().isNotEmpty) {
    return argValue.trim();
  }

  // 2. Try to infer from CWD
  final String? inferred = _inferFromCwd(projectRoot, config);
  if (inferred != null) {
    return inferred;
  }

  if (!interactive) {
    throw StateError('Feature name is required as a positional argument in non-interactive mode.');
  }

  // 3. Registered features → Select prompt
  final List<String> known = config.features.keys.toList()..sort();
  if (known.isNotEmpty) {
    final int index = Select(
      prompt: 'Target feature',
      options: known,
    ).interact();
    return known[index];
  }

  // 4. Free-form input
  return Input(
    prompt: 'Feature name (snake_case)',
    validator: (String val) => val.trim().isNotEmpty && RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(val.trim()),
  ).interact().trim();
}

/// Inspects [Directory.current] and walks upward. If any segment of the path
/// after the features root (resolved from [config.featuresPath]) matches a
/// known folder, that folder name is returned.
///
/// Example:
///   projectRoot           = /home/user/my_app
///   config.featuresPath   = lib/features
///   CWD                   = /home/user/my_app/lib/features/auth/presentation/blocs
///   → returns 'auth'
String? _inferFromCwd(String projectRoot, SimplexConfig config) {
  final String featuresAbsPath = p.join(projectRoot, config.featuresPath);
  final String cwd = Directory.current.path;

  // Normalise both paths so comparison is reliable
  final String normCwd = p.normalize(cwd);
  final String normFeatures = p.normalize(featuresAbsPath);

  // CWD must be inside (or equal to) the features dir
  if (!normCwd.startsWith(normFeatures)) {
    return null;
  }

  // Relative path from features dir → first segment is the feature name
  final String relative = p.relative(normCwd, from: normFeatures);
  final List<String> parts = p.split(relative);
  if (parts.isEmpty || parts.first == '.') {
    return null;
  }

  final String candidate = parts.first;

  // Must be valid snake_case directory
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(candidate)) {
    return null;
  }

  return candidate;
}
