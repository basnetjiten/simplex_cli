/// Created on: {{created_at}}
/// Generated with Simplex CLI

{{#use_graphql}}
import 'package:{{package_name}}/features/{{feature_name}}/domain/sources/{{feature_name}}_source.dart';
import 'package:simplex/base/simplex_base_remote_source.dart';
import 'package:injectable/injectable.dart';
import 'package:ferry/ferry.dart';
import 'package:fpdart/fpdart.dart';
// TODO: import your Ferry TypedLink client and generated GXData types here.
// Example:
//   import 'package:ferry/ferry.dart';
//   import 'package:{{package_name}}/features/{{feature_name}}/data/graphql/__generated__/...';

@Injectable(as: {{feature_class}}Source)
class {{feature_class}}RemoteSourceImpl extends SimplexGraphqlRemoteSource implements {{feature_class}}Source {
  {{feature_class}}RemoteSourceImpl(super._graphqlClient);


  @override
  Future<Unit> get{{feature_class}}() async {
// TODO: build the Ferry request and execute:
// final GForgotPasswordReq forgotMutation = GForgotPasswordReq(
//   (GForgotPasswordReqBuilder b) => b
//     ..vars.body.deviceId = deviceId
//     ..vars.body.email = email,
// );
//
// return executeGraphqlApiCall(forgotMutation);
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
class {{feature_class}}RemoteSourceImpl extends SimplexRestRemoteSource implements {{feature_class}}Source {
  {{feature_class}}RemoteSourceImpl(this._dioClient);


  @override
  Future<{{feature_class}}Model> get{{feature_class}}() async {
    // TODO: update the endpoint path
    final Response<dynamic> response = await _dio.get<dynamic>('/{{feature_name}}');
    return {{feature_class}}Model.fromJson(response.data as Map<String, dynamic>);
  }
}
{{/use_graphql}}
