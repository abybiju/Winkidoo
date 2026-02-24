class WinksBalance {
  const WinksBalance({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  final String userId;
  final int balance;
  final DateTime lastUpdated;

  factory WinksBalance.fromJson(Map<String, dynamic> json) {
    return WinksBalance(
      userId: json['user_id'] as String,
      balance: json['balance'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'balance': balance,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
