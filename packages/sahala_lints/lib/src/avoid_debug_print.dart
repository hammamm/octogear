// custom_lint_core 0.8.1's `LintRule`/`LintCode` API still uses analyzer's
// pre-8.x `ErrorReporter`/`ErrorSeverity` names (aliased, not removed).
// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The only file allowed to call `debugPrint()` directly - it's the one
/// place that's actually supposed to print, per
/// `PROJECT_DOCUMENTATION.md`'s "AppLogger: consistent logs and production
/// diagnostics" section: "Use it instead of print, debugPrint in feature
/// code, developer.log, or Dio's LogInterceptor."
const _allowedCallerSuffix = 'lib/core/service/app_logger.dart';

/// Method names this rule bans outside of [_allowedCallerSuffix]. Plain
/// `print` is intentionally not included here - the built-in `avoid_print`
/// lint (enabled in `analysis_options.yaml`) already covers that; this rule
/// only needs to cover what the built-in one doesn't.
const _bannedMethodNames = {'debugPrint'};

/// Sample/reference custom_lint rule, kept in the codebase as a template
/// for writing project-specific rules in future - not meant to be the
/// definitive lint set, just a working example of the mechanics:
///  * a [LintCode] describing the message shown at the flagged location,
///  * [CustomLintResolver.path] to exempt specific files,
///  * [CustomLintContext.registry] to visit a specific AST node kind
///    (`MethodInvocation` here; there's an `addXxx` callback for most node
///    types - see `custom_lint_visitor`'s `LintRuleNodeRegistry`) and
///    [ErrorReporter.atNode] to report at one.
///
/// What it actually enforces: `debugPrint()` calls belong only inside
/// `AppLogger` (see [_allowedCallerSuffix] above) - everywhere else should
/// go through `AppLogger.log`/`AppLogger.error` instead, so logs are
/// consistent locally and actually show up in Crashlytics in release
/// builds (a bare `debugPrint` never does).
class AvoidDebugPrint extends DartLintRule {
  const AvoidDebugPrint() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_debug_print',
    problemMessage: "Don't call debugPrint() directly.",
    correctionMessage:
        'Use AppLogger.log(...) (or AppLogger.error(...) for failures) '
        'from $_allowedCallerSuffix instead - see that file\'s doc comment.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.path.replaceAll('\\', '/');
    if (path.endsWith(_allowedCallerSuffix)) return;

    context.registry.addMethodInvocation((node) {
      if (!_bannedMethodNames.contains(node.methodName.name)) return;
      reporter.atNode(node, _code);
    });
  }
}
