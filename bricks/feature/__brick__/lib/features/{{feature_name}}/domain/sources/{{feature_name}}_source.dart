{{#use_graphql}}
import 'package:fpdart/fpdart.dart';

/// Abstract source contract for [{{feature_class}}].
/// Implementations live in data/sources/ and return Ferry GXData objects.
/// Replace [Unit] with the actual Ferry-generated GXData type after generation.
abstract class {{feature_class}}Source {
  Future<Unit> get{{feature_class}}();
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
