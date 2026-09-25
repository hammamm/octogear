import 'dart:io';

import 'package:sahala_lints/src/avoid_debug_print.dart';
import 'package:test/test.dart';

void main() {
  final rule = const AvoidDebugPrint();

  test('flags debugPrint() outside the allowlisted caller', () async {
    final errors = await rule.testAnalyzeAndRun(
      File('test_fixtures/lib/features/some_screen.dart').absolute,
    );

    expect(errors, hasLength(1));
    expect(errors.single.diagnosticCode.name, 'avoid_debug_print');
  });

  test('does not flag debugPrint() inside app_logger.dart', () async {
    final errors = await rule.testAnalyzeAndRun(
      File('test_fixtures/lib/core/service/app_logger.dart').absolute,
    );

    expect(errors, isEmpty);
  });
}
