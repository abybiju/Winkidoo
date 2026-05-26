import 'dart:ui';

/// A tone/mood overlay that modifies how a chat message sounds.
class TonePreset {
  const TonePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.promptInstructions,
    required this.color,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final String promptInstructions;
  final Color color;

  bool get isNone => id == 'none';
}
