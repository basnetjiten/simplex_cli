{{#use_graphql}}
import 'package:{{package_name}}/features/{{feature_name}}/domain/sources/{{feature_name}}_source.dart';
import 'package:injectable/injectable.dart';

// TODO: import your Ferry TypedLink client and generated GXData types here.
// Example:
//   import 'package:ferry/ferry.dart';
//   import 'package:{{package_name}}/features/{{feature_name}}/data/graphql/__generated__/...';

@Injectable(as: {{feature_class}}Source)
class {{feature_class}}RemoteSourceImpl implements {{feature_class}}Source {
  {{feature_class}}RemoteSourceImpl(this._client);

  // TODO: replace [dynamic] with your DI-registered Ferry TypedLink
  final dynamic _client;

  @override
  Future<dynamic> get{{feature_class}}() async {
    // TODO: build the Ferry request and execute:
    // final req = G{{feature_class}}QueryReq();
    // final result = await _client.request(req).first;
    // if (result.hasErrors) throw result.graphqlErrors!.first;
    // return result.data!;
    throw UnimplementedError('get{{feature_class}} not implemented yet');
  }
}
{{/use_graphql}}
{{^use_graphql}}
import 'package:dio/dio.dart';
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:{{package_name}}/features/{{feature_name}}/domain/sources/{{feature_name}}_source.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: {{feature_class}}Source)
class {{feature_class}}RemoteSourceImpl implements {{feature_class}}Source {
  {{feature_class}}RemoteSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<{{feature_class}}Model> get{{feature_class}}() async {
    // TODO: update the endpoint path
    final Response<dynamic> response = await _dio.get<dynamic>('/{{feature_name}}');
    return {{feature_class}}Model.fromJson(response.data as Map<String, dynamic>);
  }
}
{{/use_graphql}}
