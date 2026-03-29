/// Created on: {{created_at}}
/// Generated with Simplex CLI

part of '{{cubit_name}}_cubit.dart';

@freezed
abstract class {{cubit_class}}State with _${{cubit_class}}State {
  const factory {{cubit_class}}State({
    @Default(BlocStatus.initial()) BlocStatus status,
    {{^use_paging}}
    {{feature_class}}Model? data,
    {{/use_paging}}
    // TODO: add additional state fields as needed
  }) = _{{cubit_class}}State;
}
