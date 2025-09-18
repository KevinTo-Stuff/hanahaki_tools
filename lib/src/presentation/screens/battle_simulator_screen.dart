// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';

@RoutePage()
class BattleSimulatorScreen extends StatelessWidget {
  const BattleSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Simulator')),
      body: const Center(child: Text('Battle Simulator Screen')),
    );
  }
}
