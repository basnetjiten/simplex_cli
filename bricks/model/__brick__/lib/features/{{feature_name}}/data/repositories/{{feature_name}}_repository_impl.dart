import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:{{package_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';
import 'package:{{package_name}}/features/{{feature_name}}/domain/sources/{{feature_name}}_source.dart';
import 'package:injectable/injectable.dart';
import 'package:simplex/base/simplex_base_repository.dart';
import 'package:simplex/typedefs/typedefs.dart';

@Injectable(as: {{feature_class}}Repository)
class {{feature_class}}RepositoryImpl extends SimplexBaseRepository
    implements {{feature_class}}Repository {
  {{feature_class}}RepositoryImpl(this._source);

  final {{feature_class}}Source _source;

  @override
  EitherResponse<{{feature_class}}Model> get{{feature_class}}() => processApiCall(
        call: _source.get{{feature_class}}(),
        {{#use_graphql}}
        onSuccess: (dynamic data) => {{feature_class}}Model.fromRemote(data),
        {{/use_graphql}}
        {{^use_graphql}}
        onSuccess: ({{feature_class}}Model data) => data,
        {{/use_graphql}}
      );
}
