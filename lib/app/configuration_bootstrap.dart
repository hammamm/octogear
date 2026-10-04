import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/configuration/app_configuration.dart';
import '../core/configuration/api_configuration_loader.dart';
import '../core/design_system/octogear_theme.dart';
import '../core/widgets/octogear_brand_header.dart';
import '../core/widgets/octogear_page_scaffold.dart';
import '../core/widgets/octogear_surface_card.dart';

/// Holds the entire API/session provider tree until its destination is known.
/// Once resolved, configuration stays immutable for this app launch.
class ConfigurationBootstrap extends StatefulWidget {
  const ConfigurationBootstrap({
    required this.loadConfiguration,
    required this.builder,
    super.key,
  });

  final Future<AppConfiguration> Function() loadConfiguration;
  final Widget Function(AppConfiguration configuration) builder;

  @override
  State<ConfigurationBootstrap> createState() => _ConfigurationBootstrapState();
}

class _ConfigurationBootstrapState extends State<ConfigurationBootstrap> {
  late Future<AppConfiguration> _configuration;

  @override
  void initState() {
    super.initState();
    _configuration = widget.loadConfiguration();
  }

  void _retry() {
    setState(() {
      _configuration = widget.loadConfiguration();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfiguration>(
      future: _configuration,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return widget.builder(snapshot.requireData);
        }
        final failed = snapshot.connectionState == ConnectionState.done;
        final invalidLocalUrl =
            snapshot.error is LocalApiConfigurationUnavailable;
        return MaterialApp(
          title: 'OctoGear',
          debugShowCheckedModeBanner: false,
          theme: OctoGearTheme.forLocale(context.locale),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Builder(
            builder: (context) => OctoGearPageScaffold(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OctoGearBrandHeader(),
                  const SizedBox(height: OctoGearSpacing.large),
                  OctoGearSurfaceCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!failed) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: OctoGearSpacing.medium),
                        ],
                        Text(
                          context.tr(
                            failed
                                ? (invalidLocalUrl
                                      ? 'startup.invalid_configuration'
                                      : 'startup.unavailable')
                                : 'startup.connecting',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (failed && !invalidLocalUrl) ...[
                          const SizedBox(height: OctoGearSpacing.medium),
                          FilledButton(
                            onPressed: _retry,
                            child: Text(context.tr('common.retry')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
