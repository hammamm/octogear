import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White background
        Container(color: Theme.of(context).colorScheme.surface),

        // Top gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.25, 0.75, 1.0],
              colors: [
                Color(0xFFF7D9EA),
                Color(0xFFEAF4F8),
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
        ),

        SafeArea(child: child),
      ],
    );
  }
}
