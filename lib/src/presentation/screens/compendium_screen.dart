// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/annotations.dart';

@RoutePage()
class CompendiumScreen extends StatelessWidget {
  const CompendiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compendium')),
      body: const Center(child: Text('Compendium Screen')),
    );
  }
}
