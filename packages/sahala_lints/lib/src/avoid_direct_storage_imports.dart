// custom_lint_core 0.8.1's `LintRule`/`LintCode` API still uses analyzer's
// pre-8.x `ErrorReporter`/`ErrorSeverity` names (aliased, not removed).
// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The only app files allowed to import `shared_preferences` /
/// `flutter_secure_storage` directly. New OctoGear code uses `AppStorage`;
/// the legacy service is temporarily allowed only during the migration.
const _allowedCallerSuffixes = {
  'lib/core/service/local_storage_service.dart',
  'lib/core/storage/app_storage.dart',
};

/// Package import URIs this rule bans outside of [_allowedCallerSuffixes].
const _bannedImportUris = {
  'package:shared_preferences/shared_preferences.dart',
  'package:flutter_secure_storage/flutter_secure_storage.dart',
};

/// Forces every plain-preference and secure-storage read/write through
/// `LocalStorageService` instead of importing `shared_preferences` /
/// `flutter_secure_storage` directly elsewhere in the app.
///
/// Test files are exempt (path contains `/test/`) - a test for
/// the storage boundary legitimately needs `shared_preferences`' own
/// `SharedPreferences.setMockInitialValues` to set up fake persisted state;
/// that's test scaffolding, not the app reaching around the service.
class AvoidDirectStorageImports extends DartLintRule {
  const AvoidDirectStorageImports() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_direct_storage_imports',
    problemMessage:
        "Don't import shared_preferences/flutter_secure_storage directly.",
    correctionMessage: 'Use the approved core storage boundary instead.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.path.replaceAll('\\', '/');
    if (_allowedCallerSuffixes.any((suffix) => path.endsWith(suffix)) ||
        path.contains('/test/')) {
      return;
    }

    context.registry.addImportDirective((node) {
      if (!_bannedImportUris.contains(node.uri.stringValue)) return;
      reporter.atNode(node, _code);
    });
  }
}
