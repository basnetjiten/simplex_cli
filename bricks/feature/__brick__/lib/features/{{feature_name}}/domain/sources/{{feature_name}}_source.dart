/// Created on: {{created_at}}
/// Generated with Simplex CLI
import 'package:fpdart/fpdart.dart';
{{#use_graphql}}
// STUB: Remove this typedef after GraphQL types are generated
// EXPECTED_TYPE: G{{feature_class}}Data
typedef G{{feature_class}}Data = dynamic;

/// Abstract source contract for [{{feature_class}}].
/// Implementations live in data/sources/ and return Ferry GXData objects.
/// Replace [G{{feature_class}}Data] with the actual Ferry-generated GXData type after generation.
abstract class {{feature_class}}Source {
  Future<G{{feature_class}}Data?> get{{feature_class}}();
}
{{/use_graphql}}
{{^use_graphql}}
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';

/// Abstract source contract for [{{feature_class}}].
/// Implementations live in data/sources/ and call the REST API via Dio.
abstract class {{feature_class}}Source {
  Future<{{feature_class}}Model> get{{feature_class}}();
}
{{/use_graphql}}
