/// Serializable player save state. Persisted as JSON by [SaveService] and the
/// single source of truth for progression, economy and cosmetics.
class PlayerProfile {
  String name;
  int level;
  int xp;            // xp within the current level
  int coins;
  String title;

  Set<String> discoveredLandmarks;
  Set<String> completedMissions;
  Set<String> unlockedAchievements;
  Set<String> ownedItems;
  Map<String, String> equipped; // category -> itemId

  // Stats (drive achievements)
  int coinsCollected;
  int chestsOpened;
  int photosTaken;
  int missionsCompleted;
  int npcsTalked;
  double distanceWalked;

  // Live-ops
  String lastLoginDate;   // yyyy-mm-dd
  int loginStreak;
  String dailyClaimedDate;
  int weeklyProgress;     // missions toward weekly goal
  String weeklyResetDate;
  int luckyWheelTickets;
  int treasureMaps;
  List<String> badges;

  PlayerProfile({
    this.name = 'Traveler',
    this.level = 1,
    this.xp = 0,
    this.coins = 50,
    this.title = 'Newcomer',
    Set<String>? discoveredLandmarks,
    Set<String>? completedMissions,
    Set<String>? unlockedAchievements,
    Set<String>? ownedItems,
    Map<String, String>? equipped,
    this.coinsCollected = 0,
    this.chestsOpened = 0,
    this.photosTaken = 0,
    this.missionsCompleted = 0,
    this.npcsTalked = 0,
    this.distanceWalked = 0,
    this.lastLoginDate = '',
    this.loginStreak = 0,
    this.dailyClaimedDate = '',
    this.weeklyProgress = 0,
    this.weeklyResetDate = '',
    this.luckyWheelTickets = 1,
    this.treasureMaps = 0,
    List<String>? badges,
  })  : discoveredLandmarks = discoveredLandmarks ?? <String>{},
        completedMissions = completedMissions ?? <String>{},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        ownedItems = ownedItems ?? <String>{},
        equipped = equipped ?? <String, String>{},
        badges = badges ?? <String>[];

  /// XP required to advance from [level] to the next.
  int get xpToNext => 80 + (level * 70);

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'xp': xp,
        'coins': coins,
        'title': title,
        'discoveredLandmarks': discoveredLandmarks.toList(),
        'completedMissions': completedMissions.toList(),
        'unlockedAchievements': unlockedAchievements.toList(),
        'ownedItems': ownedItems.toList(),
        'equipped': equipped,
        'coinsCollected': coinsCollected,
        'chestsOpened': chestsOpened,
        'photosTaken': photosTaken,
        'missionsCompleted': missionsCompleted,
        'npcsTalked': npcsTalked,
        'distanceWalked': distanceWalked,
        'lastLoginDate': lastLoginDate,
        'loginStreak': loginStreak,
        'dailyClaimedDate': dailyClaimedDate,
        'weeklyProgress': weeklyProgress,
        'weeklyResetDate': weeklyResetDate,
        'luckyWheelTickets': luckyWheelTickets,
        'treasureMaps': treasureMaps,
        'badges': badges,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> j) => PlayerProfile(
        name: j['name'] ?? 'Traveler',
        level: j['level'] ?? 1,
        xp: j['xp'] ?? 0,
        coins: j['coins'] ?? 50,
        title: j['title'] ?? 'Newcomer',
        discoveredLandmarks: _toSet(j['discoveredLandmarks']),
        completedMissions: _toSet(j['completedMissions']),
        unlockedAchievements: _toSet(j['unlockedAchievements']),
        ownedItems: _toSet(j['ownedItems']),
        equipped: _toStrMap(j['equipped']),
        coinsCollected: j['coinsCollected'] ?? 0,
        chestsOpened: j['chestsOpened'] ?? 0,
        photosTaken: j['photosTaken'] ?? 0,
        missionsCompleted: j['missionsCompleted'] ?? 0,
        npcsTalked: j['npcsTalked'] ?? 0,
        distanceWalked: (j['distanceWalked'] ?? 0).toDouble(),
        lastLoginDate: j['lastLoginDate'] ?? '',
        loginStreak: j['loginStreak'] ?? 0,
        dailyClaimedDate: j['dailyClaimedDate'] ?? '',
        weeklyProgress: j['weeklyProgress'] ?? 0,
        weeklyResetDate: j['weeklyResetDate'] ?? '',
        luckyWheelTickets: j['luckyWheelTickets'] ?? 1,
        treasureMaps: j['treasureMaps'] ?? 0,
        badges: (j['badges'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      );

  static Set<String> _toSet(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toSet() ?? <String>{};

  static Map<String, String> _toStrMap(dynamic v) =>
      (v as Map?)?.map((k, val) => MapEntry(k.toString(), val.toString())) ??
      <String, String>{};
}
