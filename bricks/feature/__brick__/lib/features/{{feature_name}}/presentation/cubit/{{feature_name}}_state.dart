part of '{{feature_name}}_cubit.dart';

@freezed
abstract class {{feature_class}}State with _${{feature_class}}State {
  const factory {{feature_class}}State({
    @Default(BlocStatus.initial()) BlocStatus status,
    {{^use_paging}}
    {{feature_class}}Model? data,
    {{/use_paging}}
    // TODO: add additional state fields as needed
  }) = _{{feature_class}}State;
}
