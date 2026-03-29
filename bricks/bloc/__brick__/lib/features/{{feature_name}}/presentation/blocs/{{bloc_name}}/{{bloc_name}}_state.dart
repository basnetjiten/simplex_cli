part of '{{bloc_name}}_bloc.dart';


@freezed
abstract class {{bloc_class}}State with _${{bloc_class}}State {
  const factory {{bloc_class}}State({
   @Default(BlocStatus.initial()) BlocStatus status,
    // TODO: add data fields here, e.g:
    // MyModel? data,
  }) = _{{bloc_class}}State;

  const factory {{bloc_class}}State.initial() = _Initial{{bloc_class}}State;
}
