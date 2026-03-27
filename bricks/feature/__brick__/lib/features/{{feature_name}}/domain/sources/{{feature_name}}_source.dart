{{#use_graphql}}
/// Abstract source contract for [{{feature_class}}].
/// Implementations live in data/sources/ and return Ferry GXData objects.
/// Domain layer remains API-agnostic by using [dynamic] here until
/// ferry_generator has run. Replace [dynamic] with the generated type.
abstract class {{feature_class}}Source {
  // TODO: replace return type with the Ferry-generated GXData type
  Future<dynamic> get{{feature_class}}();
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
