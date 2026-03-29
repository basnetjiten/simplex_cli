part of '{{bloc_name}}_bloc.dart';

@freezed
abstract class {{bloc_class}}Event with _${{bloc_class}}Event {
  const factory {{bloc_class}}Event.load{{bloc_class}}() = _Load{{bloc_class}};
  // TODO: add more events
}
