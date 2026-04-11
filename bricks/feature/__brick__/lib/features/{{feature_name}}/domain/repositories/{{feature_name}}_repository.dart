/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:simplex/simplex_typedefs.dart';

abstract class {{feature_class}}Repository {
  EitherResponse<{{feature_class}}Model> get{{feature_class}}();
}
