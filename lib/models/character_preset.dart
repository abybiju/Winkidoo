/// A character persona available for chat text transformation.
class CharacterPreset {
  const CharacterPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.systemPrompt,
    this.isBuiltIn = true,
  });

  final String id;
  final String name;
  final String emoji;
  final String systemPrompt;
  final bool isBuiltIn;
}
