import 'package:{{package_name}}/features/{{feature_name}}/domain/repositories/{{repo_name}}_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:simplex/base/simplex_base_repository.dart';
import 'package:simplex/typedefs/typedefs.dart';
{{#use_graphql}}
import 'package:fpdart/fpdart.dart';
{{/use_graphql}}

@Injectable(as: {{repo_class}}Repository)
class {{repo_class}}RepositoryImpl extends SimplexBaseRepository
    implements {{repo_class}}Repository {
  {{repo_class}}RepositoryImpl(
    {{#use_graphql}}
    // TODO: inject your GraphQL client / source here
    {{/use_graphql}}
    {{^use_graphql}}
    // TODO: inject your REST source here
    {{/use_graphql}}
  );

  @override
  EitherResponse<dynamic> get{{repo_class}}() => processApiCall(
        call: throw UnimplementedError('get{{repo_class}} not implemented yet'),
        {{#use_graphql}}
        onSuccess: (dynamic data) => data,
        {{/use_graphql}}
        {{^use_graphql}}
        onSuccess: (dynamic data) => data,
        {{/use_graphql}}
      );
}
