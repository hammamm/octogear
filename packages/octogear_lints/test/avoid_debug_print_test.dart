import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:octogear_lints/src/avoid_debug_print.dart';
import 'package:test/test.dart';

File _fixtureFile(String relativePath) => File(
  PhysicalResourceProvider.INSTANCE.pathContext.normalize(
    File(relativePath).absolute.path,
  ),
);

void main() {
  final rule = const AvoidDebugPrint();

  test('flags debugPrint() outside the allowlisted caller', () async {
    final errors = await rule.testAnalyzeAndRun(
      _fixtureFile('test_fixtures/lib/features/some_screen.dart'),
    );

    expect(errors, hasLength(1));
    expect(errors.single.diagnosticCode.name, 'avoid_debug_print');
  });

  test('does not flag debugPrint() inside app_logger.dart', () async {
    final errors = await rule.testAnalyzeAndRun(
      _fixtureFile('test_fixtures/lib/core/service/app_logger.dart'),
    );

    expect(errors, isEmpty);
  });
}
