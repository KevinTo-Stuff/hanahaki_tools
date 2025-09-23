// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';

// Project imports:
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/utils/character_sort.dart';

@RoutePage()
class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  late List<Character> _characters;
  SortOption _sortOption = SortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    // If no external injection is provided, generate a default sample set.
    _characters = Character.generate(count: 6);
  }

  void _addCharacter(Character c) {
    setState(() {
      _characters.insert(0, c);
      _applySort();
    });
  }

  void _removeCharacterAt(int index) {
    setState(() {
      _characters.removeAt(index);
      _applySort();
    });
  }

  void _applySort() {
    setState(() {
      _characters = sortCharacters(_characters, _sortOption);
    });
  }

  Future<void> _showAddCharacterSheet() async {
    final nameController = TextEditingController();
    final nicknameController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Character',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: const Text('Create (minimal)'),
                      onPressed: () {
                        final name = nameController.text.trim().isEmpty
                            ? 'New'
                            : nameController.text.trim();
                        final nickname = nicknameController.text.trim().isEmpty
                            ? '${name[0]}000'
                            : nicknameController.text.trim();
                        final c = Character(
                          name: name,
                          nickname: nickname,
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
                          level: 1, resistances: {},
                        );
                        _addCharacter(c);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('Generate Random'),
                      onPressed: () {
                        final generated = Character.generate(count: 1).first;
                        _addCharacter(generated);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final c = _characters[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        key: ValueKey(c.nickname + c.name + c.level.toString()),
        leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
        title: Text('${c.name} (${c.nickname})'),
        subtitle: Text('Lv ${c.level} — HP ${c.health}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeCharacterAt(index),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _statChip('Kind', c.kindness),
                    _statChip('Prof', c.proficiency),
                    _statChip('Cha', c.charisma),
                    _statChip('Know', c.knowledge),
                    _statChip('Guts', c.guts),
                    _statChip('Luck', c.luck),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Strength: ${c.strength}  Magic: ${c.magic}  Endurance: ${c.endurance}',
                ),
                const SizedBox(height: 8),
                Text('Health: ${c.health}'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Characters'),
        actions: [
          // Small label showing the current sort, e.g. "Name ↑".
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                '${_sortOption.field == SortField.name ? 'Name' : 'Level'} ${_sortOption.direction == SortDirection.asc ? '↑' : '↓'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
          PopupMenuButton<SortField>(
            onSelected: (field) {
              setState(() {
                // If the same field is selected again, toggle direction.
                if (_sortOption.field == field) {
                  final newDir = _sortOption.direction == SortDirection.asc
                      ? SortDirection.desc
                      : SortDirection.asc;
                  _sortOption = SortOption(field: field, direction: newDir);
                } else {
                  // New field selected: default to ascending.
                  _sortOption = SortOption(
                    field: field,
                    direction: SortDirection.asc,
                  );
                }
                _applySort();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortField.name,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Name'),
                    if (_sortOption.field == SortField.name)
                      Icon(
                        _sortOption.direction == SortDirection.asc
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortField.level,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Level'),
                    if (_sortOption.field == SortField.level)
                      Icon(
                        _sortOption.direction == SortDirection.asc
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                  ],
                ),
              ),
            ],
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sort),
                // Badge showing N (name) or L (level) for active field
                if (_sortOption.field == SortField.name ||
                    _sortOption.field == SortField.level)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.0),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          _sortOption.field == SortField.name ? 'N' : 'L',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Sort',
          ),
        ],
      ),
      body: _characters.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No characters'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _characters = Character.generate(count: 6);
                      });
                    },
                    child: const Text('Generate Sample Characters'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _characters.length,
              itemBuilder: _buildCard,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCharacterSheet,
        tooltip: 'Add Character',
        child: const Icon(Icons.add),
      ),
    );
  }
}
