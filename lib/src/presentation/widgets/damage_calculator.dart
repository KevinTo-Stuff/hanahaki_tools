// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// Dart / other package imports
import 'dart:convert';
import 'dart:math' show max;
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/locator.dart';
import 'package:hanahaki_tools/src/shared/services/characters_service.dart';

// Damage calculation helpers
import 'package:hanahaki_tools/src/shared/helpers/damage_calculations.dart'
    as dmg;

/// Create a simple default `Character` used by the tools UX when no sample
/// is selected. This mirrors the previous `_defaultCharacter` helper from
/// `tools_screen.dart` and is exposed here so the presentation layer can
/// reuse it.
Character defaultCharacter(String namePrefix) => Character(
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
  resistances: {},
);

enum DamageType { physical, magical, hybrid, trueDamage }

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

  /// Convert this entry to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'attackerName': attackerName,
    'defenderName': defenderName,
    'amount': amount,
    'time': time.toIso8601String(),
    'turn': turn,
    'type': type.toString().split('.').last,
    'isCritical': isCritical,
  };

  /// Create an entry from a JSON map.
  factory DamageEntry.fromJson(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'physical';
    final dt =
        DateTime.tryParse(map['time'] as String? ?? '') ?? DateTime.now();
    final dmgType = DamageType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => DamageType.physical,
    );
    return DamageEntry(
      attackerName: map['attackerName'] as String? ?? 'Unknown',
      defenderName: map['defenderName'] as String? ?? 'Unknown',
      amount: (map['amount'] is int)
          ? map['amount'] as int
          : int.tryParse('${map['amount']}') ?? 0,
      time: dt,
      turn: (map['turn'] is int)
          ? map['turn'] as int
          : int.tryParse('${map['turn']}') ?? 0,
      type: dmgType,
      isCritical: map['isCritical'] as bool? ?? false,
    );
  }
}

class DamageCalculator extends StatefulWidget {
  final String title;

  const DamageCalculator({super.key, this.title = 'Damage Calculator'});

  @override
  State<DamageCalculator> createState() => _DamageCalculatorState();
}

class _DamageCalculatorState extends State<DamageCalculator> {
  List<Character>? sampleCharacters;
  late Character attacker;
  late Character defender;
  Character? selectedAttackerSample;
  Character? selectedDefenderSample;
  bool attackerCollapsed = false;
  bool defenderCollapsed = false;
  double physicalRatio = 0.6;
  DamageType damageType = DamageType.physical;
  bool isCritical = false;
  bool trueUseMagic = false;
  int? calculated;

  final List<DamageEntry> damageHistory = [];
  int _turnCounter = 1;

  static const _kDamageHistoryKey = 'damage_history_v1';

  @override
  void initState() {
    super.initState();
    try {
      final chars = locator<CharactersService>().getAll();
      if (chars.isNotEmpty) {
        sampleCharacters = chars;
      } else {
        sampleCharacters = Character.generate(count: 6);
      }
    } catch (e) {
      sampleCharacters = Character.generate(count: 6);
    }

    attacker = sampleCharacters!.isNotEmpty
        ? sampleCharacters!.first
        : defaultCharacter('Attacker');
    defender = sampleCharacters!.length > 1
        ? sampleCharacters![1]
        : defaultCharacter('Defender');
    selectedAttackerSample = sampleCharacters!.isNotEmpty
        ? sampleCharacters!.first
        : null;
    selectedDefenderSample = sampleCharacters!.length > 1
        ? sampleCharacters![1]
        : null;

    _loadDamageHistory();
  }

  Future<void> _loadDamageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kDamageHistoryKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        damageHistory.clear();
        for (var item in list) {
          try {
            final e = DamageEntry.fromJson(Map<String, dynamic>.from(item));
            damageHistory.add(e);
            _turnCounter = max(_turnCounter, e.turn + 1);
          } catch (_) {
            // ignore malformed entry
          }
        }
        setState(() {});
      }
    } catch (e) {
      // ignore load errors
    }
  }

  Future<void> _saveDamageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = damageHistory.map((e) => e.toJson()).toList();
      await prefs.setString(_kDamageHistoryKey, jsonEncode(list));
    } catch (e) {
      // ignore save errors
    }
  }

  void _onSwap() {
    setState(() {
      final swapped = swapCharacters(
        attacker: attacker,
        defender: defender,
        selectedAttackerSample: selectedAttackerSample,
        selectedDefenderSample: selectedDefenderSample,
      );
      attacker = swapped.attacker;
      defender = swapped.defender;
      selectedAttackerSample = swapped.selectedAttackerSample;
      selectedDefenderSample = swapped.selectedDefenderSample;
    });
  }

  void _onCalculate() {
    final calc = createDamageCalculationResult(
      damageType: damageType,
      attacker: attacker,
      defender: defender,
      physicalRatio: physicalRatio,
      isCritical: isCritical,
      trueUseMagic: trueUseMagic,
      turn: _turnCounter,
    );
    setState(() {
      calculated = calc.amount;
      damageHistory.insert(0, calc.entry);
      _turnCounter += 1;
      if (damageHistory.length > 40) {
        damageHistory.removeRange(40, damageHistory.length);
      }
    });
    _saveDamageHistory();
  }

  void _onClear() async {
    setState(() {
      damageHistory.clear();
      _turnCounter = 1;
    });
    await _saveDamageHistory();
  }

  @override
  Widget build(BuildContext context) {
    // Local helper reused from ToolsScreen's _buildCharacterSelector
    Widget buildCharacterSelector({
      required String title,
      List<Character>? samples,
      Character? selectedSample,
      required ValueChanged<Character?> onSampleChanged,
      required ValueChanged<Character> onCustomChanged,
      required Character currentCharacter,
      required bool collapsed,
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
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.04),
            width: 2,
          ),
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
                  IconButton(
                    icon: Icon(
                      collapsed ? Icons.expand_more : Icons.expand_less,
                    ),
                    color: borderColor,
                    tooltip: collapsed ? 'Expand' : 'Collapse',
                    onPressed: onToggleCollapsed,
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (collapsed)
                GestureDetector(
                  onTap: onToggleCollapsed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.04),
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
                if (isCustom)
                  // Simple placeholder when custom; the parent still provides custom editor elsewhere
                  SizedBox.shrink()
                else
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.04),
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
                            Chip(
                              label: Text('END ${selectedSample.endurance}'),
                            ),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 12),
            buildCharacterSelector(
              title: 'Attacker',
              samples: sampleCharacters,
              selectedSample: selectedAttackerSample,
              onSampleChanged: (c) => setState(() {
                selectedAttackerSample = c;
                attacker = c ?? defaultCharacter('Attacker');
              }),
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
                icon: Icon(FontAwesomeIcons.rightLeft),
                tooltip: 'Swap Attacker/Defender',
                onPressed: _onSwap,
              ),
            ),
            SizedBox(height: 4),
            buildCharacterSelector(
              title: 'Defender',
              samples: sampleCharacters,
              selectedSample: selectedDefenderSample,
              onSampleChanged: (c) => setState(() {
                selectedDefenderSample = c;
                defender = c ?? defaultCharacter('Defender');
              }),
              onCustomChanged: (c) => setState(() => defender = c),
              currentCharacter: defender,
              collapsed: defenderCollapsed,
              onToggleCollapsed: () =>
                  setState(() => defenderCollapsed = !defenderCollapsed),
              accent: Colors.blueAccent,
              icon: FontAwesomeIcons.shieldHalved,
            ),
            SizedBox(height: 12),
            _DamageOptions(
              physicalRatio: physicalRatio,
              damageType: damageType,
              isCritical: isCritical,
              onPhysicalRatioChanged: (v) => setState(() => physicalRatio = v),
              onTypeChanged: (t) => setState(() => damageType = t),
              onCriticalChanged: (v) => setState(() => isCritical = v),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onCalculate,
              child: Text('Calculate Damage'),
            ),
            SizedBox(height: 16),
            // Compact damage history: shows more entries on-screen with smaller, denser layout
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Damage History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: _onClear, child: Text('Clear')),
              ],
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
                      separatorBuilder: (_, _) => Divider(height: 6),
                      itemBuilder: (context, idx) {
                        final e = damageHistory[idx];
                        final t = e.time;
                        final timeStr =
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
                        return Row(
                          children: [
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
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: Theme.of(context).textTheme.bodySmall,
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

// Helper function that mirrors the damage calculation switch from
// `tools_screen.dart` so the logic can live with the DamageCalculator UI.
int calculateDamageResult({
  required DamageType damageType,
  required Character attacker,
  required Character defender,
  required double physicalRatio,
  required bool isCritical,
  required bool trueUseMagic,
}) {
  int result = 0;
  switch (damageType) {
    case DamageType.physical:
      result = dmg.calculatePhysicalDamage(
        attacker: attacker,
        defender: defender,
        isCritical: isCritical,
      );
    case DamageType.magical:
      result = dmg.calculateMagicalDamage(
        attacker: attacker,
        defender: defender,
        isCritical: isCritical,
      );
    case DamageType.hybrid:
      result = dmg.calculateHybridDamage(
        attacker: attacker,
        defender: defender,
        physicalRatio: physicalRatio,
        isCritical: isCritical,
      );
    case DamageType.trueDamage:
      result = dmg.calculateTrueDamage(
        attacker: attacker,
        defender: defender,
        useMagic: trueUseMagic,
        isCritical: isCritical,
      );
  }
  return result;
}

// Simple helper to return swapped characters and selected-sample pair.
class SwapResult {
  final Character attacker;
  final Character defender;
  final Character? selectedAttackerSample;
  final Character? selectedDefenderSample;

  SwapResult({
    required this.attacker,
    required this.defender,
    required this.selectedAttackerSample,
    required this.selectedDefenderSample,
  });
}

SwapResult swapCharacters({
  required Character attacker,
  required Character defender,
  required Character? selectedAttackerSample,
  required Character? selectedDefenderSample,
}) {
  return SwapResult(
    attacker: defender,
    defender: attacker,
    selectedAttackerSample: selectedDefenderSample,
    selectedDefenderSample: selectedAttackerSample,
  );
}

/// Result object returned from a full damage calculation helper. It
/// includes the numeric `amount` and a `DamageEntry` suitable for
/// appending to the compact history maintained by the tools UX.
class DamageCalculationResult {
  final int amount;
  final DamageEntry entry;

  DamageCalculationResult({required this.amount, required this.entry});
}

/// Creates a `DamageCalculationResult` for the given inputs. The caller
/// is responsible for managing the turn counter and history list length.
DamageCalculationResult createDamageCalculationResult({
  required DamageType damageType,
  required Character attacker,
  required Character defender,
  required double physicalRatio,
  required bool isCritical,
  required bool trueUseMagic,
  required int turn,
}) {
  final amount = calculateDamageResult(
    damageType: damageType,
    attacker: attacker,
    defender: defender,
    physicalRatio: physicalRatio,
    isCritical: isCritical,
    trueUseMagic: trueUseMagic,
  );

  final entry = DamageEntry(
    attackerName: attacker.name,
    defenderName: defender.name,
    amount: amount,
    time: DateTime.now(),
    type: damageType,
    isCritical: isCritical,
    turn: turn,
  );

  return DamageCalculationResult(amount: amount, entry: entry);
}
