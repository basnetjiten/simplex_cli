/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package_name}}/core/di/injector.dart';
import 'package:{{package_name}}/features/{{feature_name}}/presentation/blocs/{{page_name}}/{{page_name}}_cubit.dart';
{{#use_paging}}
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:simplex/pagination/paging_cubit.dart';
import 'package:simplex/pagination/paging_state.dart';
import 'package:simplex/simplex_paging.dart';
{{/use_paging}}
{{^use_paging}}
import 'package:simplex/simplex_forms.dart';
{{/use_paging}}

@RoutePage()
class {{page_class}}Page extends StatefulWidget {
  const {{page_class}}Page({super.key});

  @override
  State<{{page_class}}Page> createState() => _{{page_class}}PageState();
}

class _{{page_class}}PageState extends State<{{page_class}}Page> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<{{page_class}}Cubit>(
      create: (BuildContext context) => getIt<{{page_class}}Cubit>()
        {{^use_paging}}..fetch{{page_class}}(){{/use_paging}},
      {{#use_paging}}
      child: Builder(
        builder: (BuildContext context) =>
            BlocProvider<PagingCubit<int, {{feature_class}}Model>>(
          create: (BuildContext context) =>
              PagingCubit<int, {{feature_class}}Model>(
                initialKey: 1,
                fetchFn: context.read<{{page_class}}Cubit>().fetch{{page_class}},
              )..fetchNext(),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('{{page_class}}'),
            ),
            body: BlocBuilder<PagingCubit<int, {{feature_class}}Model>,
                PagingState<int, {{feature_class}}Model>>(
              builder: (
                BuildContext context,
                PagingState<int, {{feature_class}}Model> state,
              ) {
                return state.when(
                  initial: () => const SizedBox.shrink(),
                  loading: (List<{{feature_class}}Model> items) =>
                      const Center(child: CircularProgressIndicator()),
                  success: (List<{{feature_class}}Model> items, bool hasNextPage) =>
                      ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final {{feature_class}}Model item = items[index];
                      return ListTile(
                        title: Text(item.name),
                      );
                    },
                  ),
                  error: (String? message) => Center(
                    child: Text(message ?? 'An error occurred'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      {{/use_paging}}
      {{^use_paging}}
      child: Scaffold(
        appBar: AppBar(
          title: const Text('{{page_class}}'),
        ),
        body: BlocBuilder<{{page_class}}Cubit, {{page_class}}State>(
          builder: (BuildContext context, {{page_class}}State state) {
            return state.status.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              success: () => const Center(child: Text('{{page_class}} Page Content')),
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
