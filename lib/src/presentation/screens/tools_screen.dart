// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/presentation/widgets/damage_calculator.dart';
import 'package:hanahaki_tools/src/presentation/widgets/map_display.dart';
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/square_button.dart';
import 'package:hanahaki_tools/src/shared/widgets/dice/dice.dart';

@RoutePage()
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? selectedTool;
  // ToolsScreen no longer manages damage-calculation state; the
  // `DamageCalculator` widget is self-contained.

  void _onToolSelected(String tool) {
    setState(() {
      selectedTool = tool;
    });
  }

  @override
  void initState() {
    super.initState();
    // No setup needed for damage calculator here.
  }

  Widget _buildToolUX(String tool) {
    // Replace with custom UX for each tool
    switch (tool) {
      case 'Social Stat Check':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Social Stat Check',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              DiceRollerWidget(initialDieType: DieType.d20),
            ],
          ),
        );
      case 'Damage Calculation':
        return DamageCalculator();
      case 'Map Generator':
        return MapDisplay();
      case 'Ultimate Check':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Social Stat Check',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              DiceRollerWidget(initialDieType: DieType.d100),
            ],
          ),
        );
      default:
        return Center(child: Text('Unknown Tool'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: selectedTool == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && selectedTool != null) {
          setState(() {
            selectedTool = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tools')),
        body: SafeArea(
          child: selectedTool == null
              ? ListView(
                  padding: EdgeInsets.all(Dimens.radius),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Dimens.spacing,
                      crossAxisSpacing: Dimens.spacing,
                      children: [
                        SquareButton.outline(
                          title: 'Social Stat Check',
                          onPressed: () => _onToolSelected('Social Stat Check'),
                          icon: Icon(FontAwesomeIcons.dice, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Ultimate Check',
                          onPressed: () => _onToolSelected('Ultimate Check'),
                          icon: Icon(FontAwesomeIcons.star, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Damage Calculation',
                          onPressed: () =>
                              _onToolSelected('Damage Calculation'),
                          icon: Icon(FontAwesomeIcons.calculator, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Map Generator',
                          onPressed: () => _onToolSelected('Map Generator'),
                          icon: Icon(FontAwesomeIcons.map, size: 30),
                        ),
                      ],
                    ),
                  ],
                )
              : _buildToolUX(selectedTool!),
        ),
      ),
    );
  }
}

// Damage-related types (DamageType, DamageEntry, and options widget)
// were moved to `damage_calculator.dart`.

class _CharacterInput extends StatefulWidget {
  final String title;
  final ValueChanged<Character> onChanged;

  const _CharacterInput({required this.title, required this.onChanged});

  @override
  State<_CharacterInput> createState() => _CharacterInputState();
}

class _CharacterInputState extends State<_CharacterInput> {
  final _nameCtrl = TextEditingController();
  final _levelCtrl = TextEditingController(text: '1');
  final _strengthCtrl = TextEditingController(text: '5');
  final _magicCtrl = TextEditingController(text: '5');
  final _enduranceCtrl = TextEditingController(text: '5');
  final _luckCtrl = TextEditingController(text: '0');
  final _healthCtrl = TextEditingController(text: '50');

  void _emit() {
    final c = Character(
      name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : widget.title,
      nickname: _nameCtrl.text.isNotEmpty
          ? '${_nameCtrl.text[0]}01'
          : '${widget.title[0]}01',
      kindness: 0,
      proficiency: 0,
      charisma: 0,
      knowledge: 0,
      guts: 0,
      health: int.tryParse(_healthCtrl.text) ?? 50,
      strength: int.tryParse(_strengthCtrl.text) ?? 5,
      magic: int.tryParse(_magicCtrl.text) ?? 5,
      endurance: int.tryParse(_enduranceCtrl.text) ?? 5,
      luck: int.tryParse(_luckCtrl.text) ?? 0,
      level: (int.tryParse(_levelCtrl.text) ?? 1).clamp(1, 99),
      resistances: {},
    );
    widget.onChanged(c);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _levelCtrl.dispose();
    _strengthCtrl.dispose();
    _magicCtrl.dispose();
    _enduranceCtrl.dispose();
    _luckCtrl.dispose();
    _healthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (_) => _emit(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _levelCtrl,
                    decoration: InputDecoration(labelText: 'Level'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _healthCtrl,
                    decoration: InputDecoration(labelText: 'Health'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _strengthCtrl,
                    decoration: InputDecoration(labelText: 'Strength'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _magicCtrl,
                    decoration: InputDecoration(labelText: 'Magic'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _enduranceCtrl,
                    decoration: InputDecoration(labelText: 'Endurance'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _luckCtrl,
                    decoration: InputDecoration(labelText: 'Luck'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
