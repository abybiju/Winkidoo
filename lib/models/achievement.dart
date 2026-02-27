/// Lightweight achievement model; computed from existing data (no DB storage).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;
}
