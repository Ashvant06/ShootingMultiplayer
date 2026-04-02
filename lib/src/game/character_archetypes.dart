import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CharacterArchetype {
  const CharacterArchetype({
    required this.id,
    required this.name,
    required this.title,
    required this.modelAsset,
    required this.accent,
    required this.summary,
  });

  final String id;
  final String name;
  final String title;
  final String modelAsset;
  final Color accent;
  final String summary;
}

const List<CharacterArchetype> kCharacterArchetypes = <CharacterArchetype>[
  CharacterArchetype(
    id: 'paladin',
    name: 'Aurelian',
    title: 'Sunforged Paladin',
    modelAsset: 'assets/models/paladin_guard.obj',
    accent: AppTheme.amber,
    summary: 'A frontline knight clad in blessed steel and royal crimson.',
  ),
  CharacterArchetype(
    id: 'mage',
    name: 'Nyra',
    title: 'Ember Oracle',
    modelAsset: 'assets/models/ember_mage.obj',
    accent: AppTheme.rose,
    summary: 'A battle mage channeling emberfire through a crystal staff.',
  ),
  CharacterArchetype(
    id: 'ranger',
    name: 'Syl',
    title: 'Moonwood Ranger',
    modelAsset: 'assets/models/moon_ranger.obj',
    accent: AppTheme.cyan,
    summary: 'A swift hunter cloaked in enchanted leaves and moonlight.',
  ),
];

CharacterArchetype resolveArchetype(String seed) {
  if (seed.isEmpty) {
    return kCharacterArchetypes.first;
  }

  final hash = seed.codeUnits.fold<int>(0, (int value, int code) {
    return value + code;
  });
  return kCharacterArchetypes[hash % kCharacterArchetypes.length];
}
