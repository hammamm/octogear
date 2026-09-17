import 'package:flutter/material.dart';
import 'package:sahala/core/widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [Text('Home')]),
      ),
      showAppBar: true,
    );
  }
}
