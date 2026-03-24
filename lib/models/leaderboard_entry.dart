class LeaderboardEntry {
  const LeaderboardEntry({
    required this.coupleId,
    required this.totalXp,
    required this.currentLevel,
    required this.rank,
  });

  final String coupleId;
  final int totalXp;
  final int currentLevel;
  final int rank;

  /// Anonymous display label — last 4 chars of coupleId
  String get label => 'Couple #${coupleId.substring(coupleId.length - 4).toUpperCase()}';
}
