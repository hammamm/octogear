import 'package:flutter/material.dart';
import 'package:sahala/core/widgets/app_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    required this.showAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: title != null
                  ? Text(title!, style: TextStyle(fontWeight: FontWeight.w600))
                  : null,
              actions: actions,
            )
          : null,
      body: AppBackground(child: SafeArea(child: body)),
    );
  }
}
