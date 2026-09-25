import 'package:flutter/material.dart';

import '../design_system/octogear_theme.dart';

/// A responsive, keyboard-safe page foundation for feature screens.
///
/// It owns only visual layout. Controllers and business state stay in features.
class OctoGearPageScaffold extends StatelessWidget {
  const OctoGearPageScaffold({
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
            colors: [Color(0xFFF9FAFC), OctoGearColors.canvas],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: padding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      minHeight:
                          constraints.maxHeight -
                          MediaQuery.paddingOf(context).vertical,
                    ),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
