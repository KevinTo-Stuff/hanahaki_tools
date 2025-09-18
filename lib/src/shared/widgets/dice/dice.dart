// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/extensions/context_extensions.dart';

enum DieType { d4, d6, d8, d10, d12, d20, d100 }

extension DieTypeExtension on DieType {
  int get sides {
    switch (this) {
      case DieType.d4:
        return 4;
      case DieType.d6:
        return 6;
      case DieType.d8:
        return 8;
      case DieType.d10:
        return 10;
      case DieType.d12:
        return 12;
      case DieType.d20:
        return 20;
      case DieType.d100:
        return 100;
    }
  }

  String get label => 'd${sides}';
}

class DiceRollerWidget extends StatefulWidget {
  final DieType initialDieType;
  const DiceRollerWidget({Key? key, this.initialDieType = DieType.d6})
    : super(key: key);

  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget>
    with SingleTickerProviderStateMixin {
  late DieType _selectedDieType;
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentValue = 1;
  int _displayValue = 1;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _selectedDieType = widget.initialDieType;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.addListener(_updateAnimation);
  }

  void _updateAnimation() {
    if (_controller.isAnimating) {
      setState(() {
        // Show random value during animation
        _displayValue = _random.nextInt(_selectedDieType.sides) + 1;
      });
    } else {
      setState(() {
        _displayValue = _currentValue;
      });
    }
  }

  void _rollDie() {
    _currentValue = _random.nextInt(_selectedDieType.sides) + 1;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _rollDie,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + 0.3 * _animation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$_displayValue',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Dimens.spacing),
        Text('Tap die to roll', style: context.textTheme.labelSmall),
      ],
    );
  }
}
