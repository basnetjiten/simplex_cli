import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package_name}}/core/di/injector.dart';
import 'package:{{package_name}}/features/{{feature_name}}/presentation/blocs/{{feature_name}}_cubit.dart';
{{#use_paging}}
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:simplex/pagination/paging_cubit.dart';
import 'package:simplex/pagination/paging_state.dart';
{{/use_paging}}
{{^use_paging}}
import 'package:simplex/form/bloc_status.dart';
{{/use_paging}}

@RoutePage()
class {{feature_class}}Page extends StatefulWidget {
  const {{feature_class}}Page({super.key});

  @override
  State<{{feature_class}}Page> createState() => _{{feature_class}}PageState();
}

class _{{feature_class}}PageState extends State<{{feature_class}}Page> {
  late final {{feature_class}}Cubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<{{feature_class}}Cubit>();
    {{^use_paging}}
    _cubit.fetch{{feature_class}}();
    {{/use_paging}}
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<{{feature_class}}Cubit>.value(
      value: _cubit,
      {{#use_paging}}
      child: BlocProvider<PagingCubit<int, {{feature_class}}Model>>(
        create: (BuildContext context) =>
            PagingCubit<int, {{feature_class}}Model>(
              initialKey: 1,
              fetchFn: _cubit.fetch{{feature_class}},
            )..fetchNext(),
        child: Builder(
          builder: (BuildContext context) => Scaffold(
            appBar: AppBar(
              title: const Text('{{feature_class}}'),
            ),
            body: BlocBuilder<
                PagingCubit<int, {{feature_class}}Model>,
                PagingState<int, {{feature_class}}Model>>(
              builder: (BuildContext context,
                  PagingState<int, {{feature_class}}Model> state) {
                // TODO: replace with PagedSliverList or your custom paged widget
                return const Center(child: Text('Add your paged UI here'));
              },
            ),
          ),
        ),
      ),
      {{/use_paging}}
      {{^use_paging}}
      child: Scaffold(
        appBar: AppBar(
          title: const Text('{{feature_class}}'),
        ),
        body: BlocBuilder<{{feature_class}}Cubit, {{feature_class}}State>(
          builder: (BuildContext context, {{feature_class}}State state) {
            return state.status.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              success: () => const Center(child: Text('{{feature_class}} Page Content')),
              error: (String? message) => Center(
                child: Text(message ?? 'An error occurred'),
              ),
            );
          },
        ),
      ),
      {{/use_paging}}
    );
  }
}
