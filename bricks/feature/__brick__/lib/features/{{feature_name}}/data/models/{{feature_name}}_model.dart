/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:freezed_annotation/freezed_annotation.dart';

part '{{feature_name}}_model.freezed.dart';
part '{{feature_name}}_model.g.dart';

@freezed
abstract class {{feature_class}}Model with _${{feature_class}}Model {
  const factory {{feature_class}}Model({
    required String id,
    // TODO: add fields
  }) = _{{feature_class}}Model;

  factory {{feature_class}}Model.fromJson(Map<String, dynamic> json) =>
      _${{feature_class}}ModelFromJson(json);

  {{#use_graphql}}
  /// Convert from Ferry-generated GXData object.
  // STUB: Replace dynamic with generated Ferry type
  // EXPECTED_TYPE: G{{feature_class}}Data
  factory {{feature_class}}Model.fromRemote(dynamic remote) => {{feature_class}}Model(
        id: remote.id as String,
        // TODO: map fields from remote
      );
  {{/use_graphql}}
}
