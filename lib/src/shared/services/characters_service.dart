// Flutter imports:
import 'package:flutter/services.dart' show rootBundle;

// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:hanahaki_tools/src/shared/models/character.dart';
import 'package:hanahaki_tools/src/shared/locator.dart';
import 'package:hanahaki_tools/src/shared/services/storage/storage.dart';

class CharactersService {
  static const _kStorageKey = 'characters_v1';

  List<Character> _characters = [];

  Future<void> init() async {
    // Try to read from storage first
    try {
      final storage = locator<Storage>();
      final stored = await storage.read<String>(key: _kStorageKey);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _characters = decoded
            .map((e) => Character.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // Load from bundled asset
        await _loadFromAssetAndPersist();
      }
    } catch (e) {
      // If anything fails, fall back to loading from asset
      await _loadFromAssetAndPersist();
    }

    // If still empty, generate 10 characters and persist
    if (_characters.isEmpty) {
      _characters = Character.generate(count: 10);
      await _persist();
    }
  }

  Future<void> _loadFromAssetAndPersist() async {
    try {
      final s = await rootBundle.loadString('assets/json/characters.json');
      if (s.trim().isNotEmpty) {
        final decoded = jsonDecode(s) as List<dynamic>;
        _characters = decoded
            .map((e) => Character.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (_characters.isNotEmpty) await _persist();
      }
    } catch (e) {
      // ignore errors; caller will handle fallback
    }
  }

  Future<void> _persist() async {
    try {
      final storage = locator<Storage>();
      final list = _characters.map((c) => c.toJson()).toList();
      await storage.writeString(key: _kStorageKey, value: jsonEncode(list));
    } catch (e) {
      // ignore persistence errors
    }
  }

  List<Character> getAll() => List.unmodifiable(_characters);

  Future<void> saveAll(List<Character> chars) async {
    _characters = List.from(chars);
    await _persist();
  }
}
