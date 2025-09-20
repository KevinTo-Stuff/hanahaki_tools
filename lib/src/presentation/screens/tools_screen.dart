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
  // Collapse state for attacker/defender panels
  bool attackerCollapsed = false;
  bool defenderCollapsed = false;
  List<Character>? sampleCharacters;
  Character? selectedAttackerSample;
  Character? selectedDefenderSample;
  DamageType damageType = DamageType.physical;
  double physicalRatio = 0.6;
  bool isCritical = false;
  bool trueUseMagic = false;
  int? calculated;
  // Keep a compact history of recent damage results so more can be seen on screen
  final List<DamageEntry> damageHistory = [];
  int _turnCounter = 1;

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
    setState(() {
      calculated = result;
      // Append to compact history (most recent first)
      damageHistory.insert(
        0,
        DamageEntry(
          attackerName: attacker.name,
          defenderName: defender.name,
          amount: result,
          time: DateTime.now(),
          type: damageType,
          isCritical: isCritical,
          turn: _turnCounter,
        ),
      );
      _turnCounter += 1;
      // keep history reasonably sized
      if (damageHistory.length > 40)
        damageHistory.removeRange(40, damageHistory.length);
    });
  }

  Widget _buildCharacterSelector({
    required String title,
    List<Character>? samples,
    Character? selectedSample,
    required ValueChanged<Character?> onSampleChanged,
    required ValueChanged<Character> onCustomChanged,
    // current character instance (used when collapsed to show name)
    required Character currentCharacter,
    // whether this selector is collapsed
    required bool collapsed,
    // toggle collapse state
    required VoidCallback onToggleCollapsed,
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: borderColor),
                  ),
                ),
                // collapse/expand toggle
                IconButton(
                  icon: Icon(collapsed ? Icons.expand_more : Icons.expand_less),
                  color: borderColor,
                  tooltip: collapsed ? 'Expand' : 'Collapse',
                  onPressed: onToggleCollapsed,
                ),
              ],
            ),
            SizedBox(height: 8),
            // When collapsed, only show the selected character name in a compact row
            if (collapsed)
              GestureDetector(
                onTap: onToggleCollapsed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentCharacter.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 18, color: borderColor),
                    ],
                  ),
                ),
              )
            else ...[
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
                  currentCharacter: attacker,
                  collapsed: attackerCollapsed,
                  onToggleCollapsed: () =>
                      setState(() => attackerCollapsed = !attackerCollapsed),
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
                  currentCharacter: defender,
                  collapsed: defenderCollapsed,
                  onToggleCollapsed: () =>
                      setState(() => defenderCollapsed = !defenderCollapsed),
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
                // Compact damage history: shows more entries on-screen with smaller, denser layout
                Text(
                  'Damage History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220),
                  child: damageHistory.isEmpty
                      ? Text('No recent calculations')
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          itemCount: damageHistory.length,
                          separatorBuilder: (_, __) => Divider(height: 6),
                          itemBuilder: (context, idx) {
                            final e = damageHistory[idx];
                            // compact time string
                            final t = e.time;
                            final timeStr =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
                            return Row(
                              children: [
                                // turn and small icon
                                Text(
                                  '#${e.turn}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  e.type == DamageType.physical
                                      ? Icons.share_outlined
                                      : e.type == DamageType.magical
                                      ? Icons.auto_fix_high
                                      : e.type == DamageType.hybrid
                                      ? Icons.flash_on
                                      : Icons.remove_red_eye,
                                  size: 14,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e.attackerName} → ${e.defenderName}: ${e.amount} HP',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      e.isCritical ? 'CRIT' : '',
                                      style: TextStyle(
                                        color: e.isCritical ? Colors.red : null,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
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

/// Compact damage history entry used by the ToolsScreen damage calculator UX.
class DamageEntry {
  final String attackerName;
  final String defenderName;
  final int amount;
  final DateTime time;
  final int turn;
  final DamageType type;
  final bool isCritical;

  DamageEntry({
    required this.attackerName,
    required this.defenderName,
    required this.amount,
    required this.time,
    required this.turn,
    required this.type,
    required this.isCritical,
  });
}
