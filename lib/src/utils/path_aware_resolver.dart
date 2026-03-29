import 'dart:io';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as p;
import 'package:simplex_cli/src/config/simplex_config.dart';

/// Resolves the feature name from:
/// 1. Explicit argument
/// 2. Current working directory (if inside a feature subfolder)
/// 3. Interactive prompt (if fallback allowed)
String resolveFeatureName({
  required SimplexConfig config,
  required String projectRoot,
  String? argValue,
  bool interactive = true,
}) {
  if (argValue != null && argValue.isNotEmpty) return argValue;

  final String cwd = Directory.current.path;
  final String featuresAbsPath = p.join(projectRoot, config.featuresPath);

  if (p.isWithin(featuresAbsPath, cwd)) {
    final String relativePath = p.relative(cwd, from: featuresAbsPath);
    final String featureName = p.split(relativePath).first;
    if (featureName.isNotEmpty && featureName != '.') {
      return featureName;
    }
  }

  if (interactive) {
    final List<String> availableFeatures = config.features.keys.toList();
    if (availableFeatures.isEmpty) {
      return Input(prompt: 'Feature name (snake_case)').interact();
    }
    return Select(
      prompt: 'Select target feature',
      options: availableFeatures,
    ).interact().let((index) => availableFeatures[index]);
  }

  throw StateError('Feature name could not be inferred and interaction is disabled.');
}

extension Let<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
