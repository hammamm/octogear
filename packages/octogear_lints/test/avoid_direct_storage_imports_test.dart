import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:octogear_lints/src/avoid_direct_storage_imports.dart';
import 'package:test/test.dart';

File _fixtureFile(String relativePath) => File(
  PhysicalResourceProvider.INSTANCE.pathContext.normalize(
    File(relativePath).absolute.path,
  ),
);

void main() {
  final rule = const AvoidDirectStorageImports();

  test(
    'flags shared_preferences import outside the allowlisted caller',
    () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile(
          'test_fixtures/lib/features/otherfeature/uses_prefs_directly.dart',
        ),
      );

      expect(errors, hasLength(1));
      expect(errors.single.diagnosticCode.name, 'avoid_direct_storage_imports');
    },
  );

  test(
    'does not flag shared_preferences import inside app_storage.dart',
    () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('test_fixtures/lib/core/storage/app_storage.dart'),
      );

      expect(errors, isEmpty);
    },
  );
}
