// Dart imports:
import 'dart:math';

class Character {
  final String name;
  final String nickname;
  final int kindness; // MIN: 0, MAX: 5
  final int proficiency; // MIN: 0, MAX: 5
  final int charisma; // MIN: 0, MAX: 5
  final int knowledge; // MIN: 0, MAX: 5
  final int guts; // MIN: 0, MAX: 5
  final int health;
  final int strength;
  final int magic;
  final int endurance;
  final int luck;
  final int level; // MIN: 1, MAX: 99

  Character({
    required this.name,
    required this.nickname,
    required this.kindness,
    required this.proficiency,
    required this.charisma,
    required this.knowledge,
    required this.guts,
    required this.health,
    required this.strength,
    required this.magic,
    required this.endurance,
    required this.luck,
    required this.level,
  });

  Character copyWith({
    String? name,
    String? nickname,
    int? kindness,
    int? proficiency,
    int? charisma,
    int? knowledge,
    int? guts,
    int? health,
    int? strength,
    int? magic,
    int? endurance,
    int? luck,
    int? level,
  }) {
    return Character(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      kindness: kindness ?? this.kindness,
      proficiency: proficiency ?? this.proficiency,
      charisma: charisma ?? this.charisma,
      knowledge: knowledge ?? this.knowledge,
      guts: guts ?? this.guts,
      health: health ?? this.health,
      strength: strength ?? this.strength,
      magic: magic ?? this.magic,
      endurance: endurance ?? this.endurance,
      luck: luck ?? this.luck,
      level: level ?? this.level,
    );
  }

  /// Generate up to 10 random Character instances.
  ///
  /// The returned list length will be clamped to the range [0, 10].
  /// Use the optional [random] parameter to provide a seeded Random for
  /// deterministic generation (useful in tests).
  static List<Character> generate({int count = 10, Random? random}) {
    final rnd = random ?? Random();
    final n = count < 0 ? 0 : (count > 10 ? 10 : count);

    final sampleNames = [
      'Airi',
      'Hana',
      'Sora',
      'Kaito',
      'Mika',
      'Ren',
      'Yuki',
      'Akira',
      'Nao',
      'Rin',
    ];

    int randStat(int min, int max) => min + rnd.nextInt(max - min + 1);

    List<Character> out = [];
    for (var i = 0; i < n; i++) {
      final name = sampleNames[i % sampleNames.length];
      final nickname = '${name[0]}${rnd.nextInt(900) + 100}';

      final level = randStat(1, 99);
      final kindness = randStat(0, 5);
      final proficiency = randStat(0, 5);
      final charisma = randStat(0, 5);
      final knowledge = randStat(0, 5);
      final guts = randStat(0, 5);

      // Base derived stats
      // Base for strength, magic, and endurance is 5. Then add a small random
      // roll and a level-based baseline, then distribute level-granted points.
      var strength = 5 + randStat(0, 15) + (level ~/ 5);
      var magic = 5 + randStat(0, 15) + (level ~/ 6);
      var endurance = 5 + randStat(0, 15) + (level ~/ 8);
      // Luck is a value between 1 and 20 (inclusive).
      final luck = randStat(1, 20);

      // Allocate additional stat points based on level: each level grants 3 points
      // that can be assigned to strength, magic, or endurance. Distribute them
      // randomly across these three stats.
      final pointsToAssign = level * 3;
      for (var p = 0; p < pointsToAssign; p++) {
        final choice = rnd.nextInt(3);
        if (choice == 0) {
          strength += 1;
        } else if (choice == 1) {
          magic += 1;
        } else {
          endurance += 1;
        }
      }

      // Use the same max health formula as in damage_calculations.dart:
      // base = 30 + (level * 4)
      // enduranceFlat = endurance * 2
      // endurancePercent = 1 + (endurance / 200)
      // health = ((base + enduranceFlat) * endurancePercent).round()
      final baseHealth = 30 + (level * 4);
      final enduranceFlat = endurance * 2;
      final endurancePercent = 1 + (endurance / 200);
      final health = ((baseHealth + enduranceFlat) * endurancePercent).round();

      out.add(
        Character(
          name: name,
          nickname: nickname,
          kindness: kindness,
          proficiency: proficiency,
          charisma: charisma,
          knowledge: knowledge,
          guts: guts,
          health: health,
          strength: strength,
          magic: magic,
          endurance: endurance,
          luck: luck,
          level: level,
        ),
      );
    }

    return out;
  }
}
