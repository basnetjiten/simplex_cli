import 'package:freezed_annotation/freezed_annotation.dart';

part '{{model_name}}_model.freezed.dart';
part '{{model_name}}_model.g.dart';

@freezed
class {{model_class}}Model with _${{model_class}}Model {
  const factory {{model_class}}Model({
    required String id,
    // TODO: add fields
  }) = _{{model_class}}Model;

  factory {{model_class}}Model.fromJson(Map<String, dynamic> json) =>
      _${{model_class}}ModelFromJson(json);

  {{#use_graphql}}
  /// Convert from Ferry-generated GXData object.
  // TODO: replace [dynamic] with your generated Ferry type
  factory {{model_class}}Model.fromRemote(dynamic remote) => {{model_class}}Model(
        id: remote.id as String,
        // TODO: map fields from remote
      );
  {{/use_graphql}}
}
