// custom_lint_core 0.8.1's `LintRule`/`LintCode` API still uses analyzer's
// pre-8.x `ErrorReporter`/`ErrorSeverity` names (aliased, not removed).
// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The only file allowed to call easy_localization's `tr()` / `plural()`
/// directly. Every other file must go through `String.localized` /
/// `String.localizedPlural` / `String.localizedWithArg` /
/// `String.localizedWithCount`.
const _allowedCallerSuffix = 'lib/core/extensions/string_extension.dart';

/// Method names, from `package:easy_localization`, that this rule bans
/// outside of [_allowedCallerSuffix].
const _bannedMethodNames = {'tr', 'plural'};

/// Forces every translation lookup through the `String` extension in
/// `lib/core/extensions/string_extension.dart` instead of calling
/// easy_localization's `tr()` / `plural()` directly.
///
/// This is the Dart equivalent of the Swift codebase's convention of a
/// single `String.localized` shortcut for `NSLocalizedString`: one
/// documented choke point for translation lookups keeps fallback behavior,
/// argument formatting, and future changes (e.g. swapping the localization
/// package) consistent across the whole app.
class AvoidDirectLocalizationCalls extends DartLintRule {
  const AvoidDirectLocalizationCalls() : super(code: _code);

  // static const _code = LintCode(
  //   name: 'avoid_direct_localization_calls',
  //   problemMessage:
  //       "Don't call easy_localization's tr()/plural() directly.",
  //   correctionMessage:
  //       'Use String.localized, String.localizedPlural, '
  //       'String.localizedWithArg or String.localizedWithCount from '
  //       '$_allowedCallerSuffix instead.',
  //   errorSeverity: ErrorSeverity.WARNING,
  // );

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
