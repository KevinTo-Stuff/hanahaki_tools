import 'package:flutter_test/flutter_test.dart';
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/utils/character_sort.dart';

Character make(String name, int level) => Character(
  name: name,
  nickname: '${name[0]}001',
  kindness: 1,
  proficiency: 1,
  charisma: 1,
  knowledge: 1,
  guts: 1,
  health: 30,
  strength: 5,
  magic: 5,
  endurance: 5,
  luck: 1,
  level: level,
);

void main() {
  test('sort by name ascending', () {
    final list = [make('Charlie', 5), make('alice', 3), make('bob', 4)];
    final sorted = sortCharacters(list, SortOption.nameAsc);
    expect(sorted.map((c) => c.name).toList(), ['alice', 'bob', 'Charlie']);
  });

  test('sort by name descending', () {
    final list = [make('Charlie', 5), make('alice', 3), make('bob', 4)];
    final sorted = sortCharacters(list, SortOption.nameDesc);
    expect(sorted.map((c) => c.name).toList(), ['Charlie', 'bob', 'alice']);
  });

  test('sort by level ascending', () {
    final list = [make('A', 10), make('B', 2), make('C', 5)];
    final sorted = sortCharacters(list, SortOption.levelAsc);
    expect(sorted.map((c) => c.level).toList(), [2, 5, 10]);
  });

  test('sort by level descending', () {
    final list = [make('A', 10), make('B', 2), make('C', 5)];
    final sorted = sortCharacters(list, SortOption.levelDesc);
    expect(sorted.map((c) => c.level).toList(), [10, 5, 2]);
  });
}
