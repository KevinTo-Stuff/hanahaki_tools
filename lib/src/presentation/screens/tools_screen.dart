// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/square_button.dart';
import 'package:hanahaki_tools/src/shared/widgets/dice/dice.dart';
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/helpers/damage_calculations.dart'
    as dmg;

@RoutePage()
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? selectedTool;
  // Damage calc state
  late Character attacker;
  late Character defender;
  List<Character>? sampleCharacters;
  Character? selectedAttackerSample;
  Character? selectedDefenderSample;
  DamageType damageType = DamageType.physical;
  double physicalRatio = 0.6;
  bool isCritical = false;
  bool trueUseMagic = false;
  int? calculated;

  Character _defaultCharacter(String namePrefix) => Character(
    name: namePrefix,
    nickname: '${namePrefix[0]}01',
    kindness: 0,
    proficiency: 0,
    charisma: 0,
    knowledge: 0,
    guts: 0,
    health: 50,
    strength: 5,
    magic: 5,
    endurance: 5,
    luck: 0,
    level: 1,
  );

  void _onToolSelected(String tool) {
    setState(() {
      selectedTool = tool;
    });
  }

  @override
  void initState() {
    super.initState();
    // generate sample characters by default
    sampleCharacters = Character.generate(count: 6);
    attacker = sampleCharacters!.isNotEmpty
        ? sampleCharacters!.first
        : _defaultCharacter('Attacker');
    defender = sampleCharacters!.length > 1
        ? sampleCharacters![1]
        : _defaultCharacter('Defender');
    selectedAttackerSample = sampleCharacters!.isNotEmpty
        ? sampleCharacters!.first
        : null;
    selectedDefenderSample = sampleCharacters!.length > 1
        ? sampleCharacters![1]
        : null;
  }

  void _calculateDamage() {
    int result = 0;
    switch (damageType) {
      case DamageType.physical:
        result = dmg.calculatePhysicalDamage(
          attacker: attacker,
          defender: defender,
          isCritical: isCritical,
        );
        break;
      case DamageType.magical:
        result = dmg.calculateMagicalDamage(
          attacker: attacker,
          defender: defender,
          isCritical: isCritical,
        );
        break;
      case DamageType.hybrid:
        result = dmg.calculateHybridDamage(
          attacker: attacker,
          defender: defender,
          physicalRatio: physicalRatio,
          isCritical: isCritical,
        );
        break;
      case DamageType.trueDamage:
        result = dmg.calculateTrueDamage(
          attacker: attacker,
          defender: defender,
          useMagic: trueUseMagic,
          isCritical: isCritical,
        );
        break;
    }
    setState(() => calculated = result);
  }

  Widget _buildCharacterSelector({
    required String title,
    List<Character>? samples,
    Character? selectedSample,
    required ValueChanged<Character?> onSampleChanged,
    required ValueChanged<Character> onCustomChanged,
    Color? accent,
    IconData? icon,
  }) {
    final options = <DropdownMenuItem<Character?>>[];
    if (samples != null) {
      for (var s in samples) {
        options.add(DropdownMenuItem(value: s, child: Text(s.name)));
      }
    }
    options.add(DropdownMenuItem(value: null, child: Text('Custom')));

    final isCustom = selectedSample == null;

    final borderColor = accent ?? Theme.of(context).colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor.withOpacity(0.6), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: borderColor),
                if (icon != null) SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: borderColor),
                ),
              ],
            ),
            SizedBox(height: 8),
            DropdownButton<Character?>(
              isExpanded: true,
              value: selectedSample,
              items: options,
              onChanged: (v) => onSampleChanged(v),
            ),
            SizedBox(height: 8),
            // Show the editor when Custom is selected
            if (isCustom)
              _CharacterInput(title: title, onChanged: onCustomChanged)
            else
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Selected: ${selectedSample.name}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Lvl ${selectedSample.level}')),
                        Chip(label: Text('STR ${selectedSample.strength}')),
                        Chip(label: Text('MAG ${selectedSample.magic}')),
                        Chip(label: Text('END ${selectedSample.endurance}')),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _swapCharacters() {
    setState(() {
      final tmpChar = attacker;
      attacker = defender;
      defender = tmpChar;

      final tmpSample = selectedAttackerSample;
      selectedAttackerSample = selectedDefenderSample;
      selectedDefenderSample = tmpSample;
    });
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
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Damage Calculator',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 12),
                _buildCharacterSelector(
                  title: 'Attacker',
                  samples: sampleCharacters,
                  selectedSample: selectedAttackerSample,
                  onSampleChanged: (c) {
                    setState(() {
                      selectedAttackerSample = c;
                      attacker = c ?? _defaultCharacter('Attacker');
                    });
                  },
                  onCustomChanged: (c) => setState(() => attacker = c),
                  accent: Colors.redAccent,
                  icon: FontAwesomeIcons.crosshairs,
                ),
                SizedBox(height: 12),
                Center(
                  child: IconButton(
                    icon: Icon(FontAwesomeIcons.exchangeAlt),
                    tooltip: 'Swap Attacker/Defender',
                    onPressed: _swapCharacters,
                  ),
                ),
                SizedBox(height: 4),
                _buildCharacterSelector(
                  title: 'Defender',
                  samples: sampleCharacters,
                  selectedSample: selectedDefenderSample,
                  onSampleChanged: (c) {
                    setState(() {
                      selectedDefenderSample = c;
                      defender = c ?? _defaultCharacter('Defender');
                    });
                  },
                  onCustomChanged: (c) => setState(() => defender = c),
                  accent: Colors.blueAccent,
                  icon: FontAwesomeIcons.shieldAlt,
                ),
                SizedBox(height: 12),
                _DamageOptions(
                  physicalRatio: physicalRatio,
                  damageType: damageType,
                  isCritical: isCritical,
                  onPhysicalRatioChanged: (v) =>
                      setState(() => physicalRatio = v),
                  onTypeChanged: (t) => setState(() => damageType = t),
                  onCriticalChanged: (v) => setState(() => isCritical = v),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _calculateDamage,
                  child: Text('Calculate Damage'),
                ),
                SizedBox(height: 16),
                if (calculated != null) ...[
                  Text(
                    'Result',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${calculated!} HP',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ],
            ),
          ),
        );
      case 'Map Generator':
        return Center(child: Text('Map Generator UX'));
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
    return WillPopScope(
      onWillPop: () async {
        if (selectedTool != null) {
          setState(() {
            selectedTool = null;
          });
          return false;
        }
        return true;
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

enum DamageType { physical, magical, hybrid, trueDamage }

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

class _DamageOptions extends StatelessWidget {
  final double physicalRatio;
  final DamageType damageType;
  final bool isCritical;
  final ValueChanged<double> onPhysicalRatioChanged;
  final ValueChanged<DamageType> onTypeChanged;
  final ValueChanged<bool> onCriticalChanged;

  const _DamageOptions({
    required this.physicalRatio,
    required this.damageType,
    required this.isCritical,
    required this.onPhysicalRatioChanged,
    required this.onTypeChanged,
    required this.onCriticalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            DropdownButton<DamageType>(
              value: damageType,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: DamageType.physical,
                  child: Text('Physical'),
                ),
                DropdownMenuItem(
                  value: DamageType.magical,
                  child: Text('Magical'),
                ),
                DropdownMenuItem(
                  value: DamageType.hybrid,
                  child: Text('Hybrid'),
                ),
                DropdownMenuItem(
                  value: DamageType.trueDamage,
                  child: Text('True Damage'),
                ),
              ],
              onChanged: (v) => v != null ? onTypeChanged(v) : null,
            ),
            if (damageType == DamageType.hybrid) ...[
              SizedBox(height: 8),
              Text('Physical ratio: ${physicalRatio.toStringAsFixed(2)}'),
              Slider(
                value: physicalRatio,
                min: 0.0,
                max: 1.0,
                onChanged: onPhysicalRatioChanged,
              ),
            ],
            Row(
              children: [
                Checkbox(
                  value: isCritical,
                  onChanged: (v) => onCriticalChanged(v ?? false),
                ),
                SizedBox(width: 8),
                Text('Critical'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
