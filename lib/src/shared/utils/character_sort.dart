// Utility to sort Character lists by different options.
import 'package:hanahaki_tools/src/shared/models/character.dart';

enum SortField { name, level }

enum SortDirection { asc, desc }

class SortOption {
  final SortField field;
  final SortDirection direction;

  const SortOption({required this.field, required this.direction});

  static const nameAsc = SortOption(
    field: SortField.name,
    direction: SortDirection.asc,
  );
  static const nameDesc = SortOption(
    field: SortField.name,
    direction: SortDirection.desc,
  );
  static const levelAsc = SortOption(
    field: SortField.level,
    direction: SortDirection.asc,
  );
  static const levelDesc = SortOption(
    field: SortField.level,
    direction: SortDirection.desc,
  );
}

List<Character> sortCharacters(List<Character> input, SortOption option) {
  final out = List<Character>.from(input);
  int modifier = option.direction == SortDirection.asc ? 1 : -1;

  if (option.field == SortField.name) {
    out.sort(
      (a, b) => modifier * a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  } else {
    out.sort((a, b) => modifier * a.level.compareTo(b.level));
  }

  return out;
}
