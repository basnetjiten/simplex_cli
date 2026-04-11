/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
{{#use_paging}}
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
{{/use_paging}}
import 'package:{{package_name}}/features/{{feature_name}}/domain/repositories/{{feature_name}}_repository.dart';
{{^use_paging}}
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
{{/use_paging}}
import 'package:simplex/errors/app_error.dart';
import 'package:simplex/simplex_forms.dart';
import 'package:simplex/simplex_base.dart';
{{#use_paging}}
import 'package:fpdart/fpdart.dart';
{{/use_paging}}

part '{{cubit_name}}_cubit.freezed.dart';
part '{{cubit_name}}_state.dart';

@injectable
class {{cubit_class}}Cubit extends SimplexCubit<{{cubit_class}}State> {
  {{cubit_class}}Cubit(this._repository) : super(const {{cubit_class}}State());

  final {{feature_class}}Repository _repository;

  {{#use_paging}}
  /// Fetch function consumed by [PagingCubit].
  /// Returns a tuple of (items, nextPageKey) — pass null as nextPageKey when there are no more pages.
  Future<(List<{{feature_class}}Model>, int?)> fetch{{cubit_class}}(int page, String? search) async {
    final Either<AppError, {{feature_class}}Model> response = await _repository.get{{feature_class}}();
    return response.fold(
      (AppError error) {
        emit(state.copyWith(status: BlocStatus.error(error: error.toString())));
        throw error;
      },
      ({{feature_class}}Model data) {
        // TODO: adjust when your model supports list + pagination
        emit(state.copyWith(status: BlocStatus.success(apiData: ApiData<{{feature_class}}Model>.fromData(data: data))));
        return (<{{feature_class}}Model>[data], null);
      },
    );
  }
  {{/use_paging}}
  {{^use_paging}}
  Future<void> fetch{{cubit_class}}() => handleAPICall(
        call: _repository.get{{feature_class}}(),
        onSuccess: ({{feature_class}}Model data) => state.copyWith(
          status: const BlocStatus.success(),
          data: data,
        ),
        onFailure: (String error) => state.copyWith(status: BlocStatus.error(error: error)),
      );
  {{/use_paging}}
}
