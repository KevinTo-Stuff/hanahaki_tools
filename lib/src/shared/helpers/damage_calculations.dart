// Dart imports:
import 'dart:math';

// Project imports:
import '../models/character.dart';

/// Damage and health calculation helpers.
///
/// All returned values are integers. Formulas intentionally keep values
/// deterministic and simple so they are easy to test and tune.

/// Calculate base physical damage from attacker stats.
/// Uses attacker's `level` and `strength`.
int physicalDamage({required int level, required int strength}) {
  // Base scales with strength, slightly with level.
  final base = (strength * 2) + (level ~/ 2);
  // Add small random variance of +/-5% for flavour (deterministic here by using hash)
  final variance = max(1, (base * 5) ~/ 100);
  return base + variance;
}

/// Calculate base magical damage from attacker stats.
/// Uses attacker's `level` and `magic`.
int magicalDamage({required int level, required int magic}) {
  final base = (magic * 2) + (level ~/ 3);
  final variance = max(1, (base * 6) ~/ 100);
  return base + variance;
}

/// Calculate hybrid damage that blends physical and magical power.
/// Useful for weapons/skills that scale with both `strength` and `magic`.
int hybridDamage({
  required int level,
  required int strength,
  required int magic,
  double physicalRatio = 0.6,
}) {
  // physicalRatio indicates how much weight to give physical (0.0-1.0)
  final phys = physicalDamage(level: level, strength: strength);
  final mag = magicalDamage(level: level, magic: magic);
  // blend and apply a small level scaling bonus
  final blended = (phys * physicalRatio) + (mag * (1 - physicalRatio));
  final levelBonus = (level / 20); // small float bonus
  return max(0, (blended * (1 + levelBonus)).round());
}

/// True damage ignores endurance (defender mitigation) and deals flat damage.
/// It still scales from attacker stats but bypasses `applyEndurance`.
int trueDamage({
  required int level,
  required int strength,
  required int magic,
  bool useMagic = false,
}) {
  final base = useMagic
      ? magicalDamage(level: level, magic: magic)
      : physicalDamage(level: level, strength: strength);
  // True damage gets a small flat boost to make it feel impactful
  return base + (level ~/ 3);
}

/// Calculate critical hit multiplier (returns multiplier as double).
/// Depends on attacker's `level` and `luck` (luck is optional).
double criticalMultiplier({required int level, int luck = 0}) {
  // Base crit chance increases very slowly with level/luck; multiplier between 1.5 and 2.5
  final bonus = (level / 200) + (luck / 200);
  return 1.5 + bonus.clamp(0.0, 1.0);
}

/// Calculate damage after defender endurance reduces incoming damage.
/// `incoming` is the raw damage (physical or magical); `endurance` reduces it.
int applyEndurance({required int incoming, required int endurance}) {
  // Endurance provides a percent damage reduction up to 60%.
  final reductionPercent = (endurance / (endurance + 50)) * 0.6; // in [0,0.6)
  final reduced = (incoming * (1 - reductionPercent)).round();
  return max(0, reduced);
}

/// Calculate final physical damage from attacker -> defender using stats.
int calculatePhysicalDamage({
  required Character attacker,
  required Character defender,
  bool isCritical = false,
}) {
  var raw = physicalDamage(level: attacker.level, strength: attacker.strength);
  if (isCritical) {
    raw = (raw * criticalMultiplier(level: attacker.level, luck: attacker.luck))
        .round();
  }
  return applyEndurance(incoming: raw, endurance: defender.endurance);
}

/// Calculate final magical damage from attacker -> defender using stats.
int calculateMagicalDamage({
  required Character attacker,
  required Character defender,
  bool isCritical = false,
}) {
  var raw = magicalDamage(level: attacker.level, magic: attacker.magic);
  if (isCritical) {
    raw = (raw * criticalMultiplier(level: attacker.level, luck: attacker.luck))
        .round();
  }
  return applyEndurance(incoming: raw, endurance: defender.endurance);
}

/// Calculate final hybrid damage from attacker -> defender.
int calculateHybridDamage({
  required Character attacker,
  required Character defender,
  double physicalRatio = 0.6,
  bool isCritical = false,
}) {
  var raw = hybridDamage(
    level: attacker.level,
    strength: attacker.strength,
    magic: attacker.magic,
    physicalRatio: physicalRatio,
  );
  if (isCritical) {
    raw = (raw * criticalMultiplier(level: attacker.level, luck: attacker.luck))
        .round();
  }
  return applyEndurance(incoming: raw, endurance: defender.endurance);
}

/// Calculate final true damage from attacker -> defender (ignores endurance).
int calculateTrueDamage({
  required Character attacker,
  required Character defender,
  bool useMagic = false,
  bool isCritical = false,
}) {
  var raw = trueDamage(
    level: attacker.level,
    strength: attacker.strength,
    magic: attacker.magic,
    useMagic: useMagic,
  );
  if (isCritical) {
    raw = (raw * criticalMultiplier(level: attacker.level, luck: attacker.luck))
        .round();
  }
  // ignores endurance
  return max(0, raw);
}

/// Simple heal amount formula based on caster stats (uses magic and level).
int healAmount({required int level, required int magic}) {
  final base = magic * 2 + (level ~/ 4);
  final bonus = (base * 10) ~/ 100; // +10%
  return base + bonus;
}

int calculatePhysicalDamageCharacters(
  Character attacker,
  Character defender, {
  bool isCritical = false,
}) => calculatePhysicalDamage(
  attacker: attacker,
  defender: defender,
  isCritical: isCritical,
);
int calculateMagicalDamageCharacters(
  Character attacker,
  Character defender, {
  bool isCritical = false,
}) => calculateMagicalDamage(
  attacker: attacker,
  defender: defender,
  isCritical: isCritical,
);
