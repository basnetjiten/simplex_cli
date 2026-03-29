/// Created on: {{created_at}}
/// Generated with Simplex CLI

import 'package:flutter_test/flutter_test.dart';
import 'package:{{package_name}}/features/{{feature_name}}/data/models/{{feature_name}}_model.dart';
import 'package:{{package_name}}/features/{{feature_name}}/data/sources/{{feature_name}}_remote_source_impl.dart';

void main() {
  late {{feature_class}}RemoteSourceImpl source;

  setUp(() {
    // TODO: inject a mock Dio or mock Ferry client
    // source = {{feature_class}}RemoteSourceImpl(mockDio);
  });

  group('{{feature_class}}RemoteSourceImpl', () {
    test('get{{feature_class}} returns {{feature_class}}Model', () async {
      // TODO: stub the dependency and assert result
      expect(true, isTrue); // placeholder
    });
  });
}
