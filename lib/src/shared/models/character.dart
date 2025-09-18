class Character {
  final String name;
  final String nickname;
  final int kindness;
  final int proficiency;
  final int charisma;
  final int knowledge;
  final int guts;
  final int health;
  final int strength;
  final int magic;
  final int endurance;
  final int luck;

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
    );
  }
}
