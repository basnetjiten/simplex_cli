import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

const String _configFileName = 'simplex.yaml';

class SimplexConfig {
  const SimplexConfig({
    required this.projectName,
    required this.packageName,
    required this.featuresPath,
    required this.testPath,
    required this.defaultApi,
    required this.features,
  });

  factory SimplexConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    final Map<String, dynamic> featuresRaw =
        (yaml['features'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{})
            .cast<String, dynamic>();

    final Map<String, FeatureConfig> features = featuresRaw.map(
      (String key, dynamic value) => MapEntry(
        key,
        FeatureConfig.fromYaml((value as Map<dynamic, dynamic>).cast<String, dynamic>()),
      ),
    );

    return SimplexConfig(
      projectName: yaml['project_name'] as String? ?? '',
      packageName: yaml['package_name'] as String? ?? '',
      featuresPath: yaml['features_path'] as String? ?? 'lib/features',
      testPath: yaml['test_path'] as String? ?? 'test/features',
      defaultApi: yaml['default_api'] as String? ?? 'graphql',
      features: features,
    );
  }

  final String projectName;
  final String packageName;
  final String featuresPath;
  final String testPath;
  final String defaultApi;
  final Map<String, FeatureConfig> features;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'project_name': projectName,
        'package_name': packageName,
        'features_path': featuresPath,
        'test_path': testPath,
        'default_api': defaultApi,
        if (features.isNotEmpty)
          'features': features.map(
            (String key, FeatureConfig value) => MapEntry<String, dynamic>(key, value.toMap()),
          ),
      };

  SimplexConfig copyWith({
    String? projectName,
    String? packageName,
    String? featuresPath,
    String? testPath,
    String? defaultApi,
    Map<String, FeatureConfig>? features,
  }) =>
      SimplexConfig(
        projectName: projectName ?? this.projectName,
        packageName: packageName ?? this.packageName,
        featuresPath: featuresPath ?? this.featuresPath,
        testPath: testPath ?? this.testPath,
        defaultApi: defaultApi ?? this.defaultApi,
        features: features ?? this.features,
      );
}

class FeatureConfig {
  const FeatureConfig({
    required this.api,
    required this.paging,
  });

  factory FeatureConfig.fromYaml(Map<String, dynamic> yaml) => FeatureConfig(
        api: yaml['api'] as String? ?? 'graphql',
        paging: yaml['paging'] as bool? ?? false,
      );

  final String api;
  final bool paging;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'api': api,
        'paging': paging,
      };
}

/// Finds the project root by walking up until simplex.yaml or pubspec.yaml is found.
String? findProjectRoot() {
  Directory dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, _configFileName)).existsSync()) {
      return dir.path;
    }
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir.path;
    }
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

/// Loads simplex.yaml from [projectRoot]. Returns null if not found.
SimplexConfig? loadConfig(String projectRoot) {
  final File file = File(p.join(projectRoot, _configFileName));
  if (!file.existsSync()) {
    return null;
  }
  final dynamic yaml = loadYaml(file.readAsStringSync());
  return SimplexConfig.fromYaml((yaml as Map<dynamic, dynamic>));
}

/// Saves [config] to simplex.yaml in [projectRoot].
void saveConfig(String projectRoot, SimplexConfig config) {
  final File file = File(p.join(projectRoot, _configFileName));
  final YamlWriter writer = YamlWriter();
  file.writeAsStringSync(writer.write(config.toMap()));
}
