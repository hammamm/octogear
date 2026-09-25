import 'dart:io';

import 'package:sahala_lints/src/avoid_direct_storage_imports.dart';
import 'package:test/test.dart';

void main() {
  final rule = const AvoidDirectStorageImports();

  test('flags shared_preferences import outside the allowlisted caller', () async {
    final errors = await rule.testAnalyzeAndRun(
      File(
        'test_fixtures/lib/features/otherfeature/uses_prefs_directly.dart',
      ).absolute,
    );

    expect(errors, hasLength(1));
    expect(errors.single.diagnosticCode.name, 'avoid_direct_storage_imports');
  });

  test('does not flag shared_preferences import inside local_storage_service.dart', () async {
    final errors = await rule.testAnalyzeAndRun(
      File('test_fixtures/lib/core/service/local_storage_service.dart').absolute,
    );

    expect(errors, isEmpty);
  });
}
