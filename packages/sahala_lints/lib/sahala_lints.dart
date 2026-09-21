import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_direct_localization_calls.dart';

/// Entry point discovered by `custom_lint` (declared as a `custom_lint`
/// dependency in the app's `analysis_options.yaml`).
PluginBase createPlugin() => _SahalaLints();

class _SahalaLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    AvoidDirectLocalizationCalls(),
  ];
}
