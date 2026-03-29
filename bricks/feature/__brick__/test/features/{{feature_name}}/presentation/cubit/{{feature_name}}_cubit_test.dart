/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:flutter_test/flutter_test.dart';
import 'package:{{package_name}}/features/{{feature_name}}/presentation/cubit/{{feature_name}}_cubit.dart';

void main() {
  late {{feature_class}}Cubit cubit;

  setUp(() {
    // TODO: inject a fake repository
    // cubit = {{feature_class}}Cubit(Fake{{feature_class}}Repository());
  });

  tearDown(() => cubit.close());

  group('{{feature_class}}Cubit', () {
    {{^use_paging}}
    test('initial state is correct', () {
      // expect(cubit.state.status, const BlocStatus.initial());
      expect(true, isTrue); // placeholder
    });

    test('fetch{{feature_class}} emits success state', () async {
      // await cubit.fetch{{feature_class}}();
      // expect(cubit.state.status, isA<BlocStatusSuccess>());
      expect(true, isTrue); // placeholder
    });
    {{/use_paging}}
    {{#use_paging}}
    test('fetch{{feature_class}} returns list and nextPageKey', () async {
      // final result = await cubit.fetch{{feature_class}}(1, null);
      // expect(result.$1, isNotEmpty);
      expect(true, isTrue); // placeholder
    });
    {{/use_paging}}
  });
}
