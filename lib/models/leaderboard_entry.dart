class LeaderboardEntry {
  final String name;
  final int score;
  final int level;
  final bool isMe;

  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.level,
    this.isMe = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j, {bool isMe = false}) =>
      LeaderboardEntry(
        name: (j['name'] ?? 'Player').toString(),
        score: j['score'] is num ? (j['score'] as num).toInt() : 0,
        level: j['level'] is num ? (j['level'] as num).toInt() : 1,
        isMe: isMe,
      );
}
