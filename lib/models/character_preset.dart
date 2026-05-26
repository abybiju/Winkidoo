import 'dart:ui';

/// A character persona available for chat text transformation.
class CharacterPreset {
  const CharacterPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.systemPrompt,
    this.isBuiltIn = true,
    this.color,
  });

  final String id;
  final String name;
  final String emoji;
  final String systemPrompt;
  final bool isBuiltIn;
  final Color? color;
}
