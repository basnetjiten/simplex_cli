/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:injectable/injectable.dart';
import 'package:{{package_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';
import 'package:simplex/simplex_base.dart';
import 'package:simplex/form/bloc_status.dart';
part '{{bloc_name}}_bloc.freezed.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part '{{bloc_name}}_event.dart';
part '{{bloc_name}}_state.dart';

@injectable
class {{bloc_class}}Bloc extends SimplexBloc<{{bloc_class}}Event, {{bloc_class}}State> {
  final {{bloc_class}}Repository _repository;

  {{bloc_class}}Bloc(this._repository) : super(const {{bloc_class}}State.initial()) {
    on<_Load{{bloc_class}}>(_onLoad{{bloc_class}});
    // TODO: register additional event handlers here
  }

  Future<void> _onLoad{{bloc_class}}(
    _Load{{bloc_class}} event,
    Emitter<{{bloc_class}}State> emit,
  ) async {
    await handleAPICall(
      emitter: emit,
      call: _repository.get{{bloc_class}}(),
      onSuccess: (dynamic data) => state.copyWith(
        status: BlocStatus.success(),
      ),
      onFailure: (String error) => state.copyWith(
        status: BlocStatus.failure(error),
      ),
    );
  }
}
