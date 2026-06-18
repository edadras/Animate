import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/player_profile.dart';
import '../models/mission.dart';
import '../models/shop_item.dart';
import '../models/achievement.dart';
import '../data/missions_data.dart';
import '../data/shop_data.dart';
import '../data/achievements_data.dart';
import '../data/landmarks_data.dart';
import '../models/leaderboard_entry.dart';
import 'save_service.dart';
import 'cloud_service.dart';

/// Central game brain: economy, leveling, missions, achievements and live-ops.
/// UI listens via [ChangeNotifier]; the 3D engine is driven through [engineSend]
/// and feeds gameplay back through the on* event entry points.
class GameState extends ChangeNotifier {
  GameState(this._save, this._cloud);
  final SaveService _save;
  final CloudService _cloud;

  bool get cloudEnabled => _cloud.enabled;
  Future<List<LeaderboardEntry>> fetchLeaderboard() => _cloud.fetchLeaderboard();

  late PlayerProfile profile;
  late List<Mission> allMissions;
  Mission? dailyMission;
  Mission? weeklyMission;

  String? activeMissionId;
  int activeProgress = 0;
  int _escortStage = 0;

  bool loaded = false;

  // --- bridges to the 3D engine and the UI ---
  void Function(String name, Map<String, dynamic> data)? engineSend;
  void Function(String message, {String icon})? onToast;
  void Function(int level)? onLevelUp;
  void Function(Achievement a)? onAchievement;
  void Function(Mission m)? onMissionComplete;

  double? _lastX, _lastZ;
  double _stepAccum = 0;
  Timer? _saveTimer;

  // ---------------------------------------------------------------------------
  Future<void> init() async {
    profile = await _save.load();
    // Cloud save: adopt the remote profile if it is clearly more advanced.
    if (_cloud.enabled) {
      final remote = await _cloud.downloadSave();
      if (remote != null) {
        final rp = PlayerProfile.fromJson(remote);
        final localScore = profile.level * 100000 + profile.coinsCollected;
        final remoteScore = rp.level * 100000 + rp.coinsCollected;
        if (remoteScore > localScore) profile = rp;
      }
    }
    allMissions = buildAllMissions();
    final now = DateTime.now();
    dailyMission = dailyMissionFor(now, allMissions);
    weeklyMission = weeklyMissionFor(now);
    _checkLiveOps(now);
    loaded = true;
    notifyListeners();
  }

  // ---- derived getters ----
  int get coins => profile.coins;
  int get level => profile.level;
  int get xp => profile.xp;
  double get xpFraction => profile.xp / profile.xpToNext;

  Mission? get activeMission {
    final id = activeMissionId;
    if (id == null) return null;
    if (dailyMission?.id == id) return dailyMission;
    if (weeklyMission?.id == id) return weeklyMission;
    for (final m in allMissions) {
      if (m.id == id) return m;
    }
    return null;
  }

  bool isMissionCompleted(String id) => profile.completedMissions.contains(id);

  bool get dailyRewardAvailable =>
      profile.dailyClaimedDate != _dateStr(DateTime.now());

  List<Achievement> get unlockedAchievements =>
      kAchievements.where((a) => profile.unlockedAchievements.contains(a.id)).toList();

  // ===========================================================================
  // MISSIONS
  // ===========================================================================
  void setActiveMission(Mission m) {
    activeMissionId = m.id;
    activeProgress = 0;
    _escortStage = 0;
    if (m.targetLandmarkId != null) {
      engineSend?.call('setWaypoint', {'id': m.targetLandmarkId});
    } else {
      engineSend?.call('clearWaypoint', {});
    }
    if (m.type == MissionType.photo) {
      engineSend?.call('photoMode', {'on': true});
    }
    _rahino('New mission: ${m.title}. ${_hint(m)}', emote: 'point');
    notifyListeners();
  }

  void abandonMission() {
    activeMissionId = null;
    engineSend?.call('clearWaypoint', {});
    engineSend?.call('photoMode', {'on': false});
    notifyListeners();
  }

  String _hint(Mission m) {
    final lm = m.targetLandmarkId != null ? landmarkById(m.targetLandmarkId!) : null;
    switch (m.type) {
      case MissionType.photo: return 'Open photo mode near ${lm?.name ?? 'the landmark'} and snap a shot.';
      case MissionType.collectCoins:
      case MissionType.souvenir: return 'Collect ${m.targetCount} coins.';
      case MissionType.chests:
      case MissionType.artifact: return 'Open hidden chests.';
      case MissionType.talk: return 'Find a ${m.npcKind} and talk.';
      case MissionType.walk: return 'Keep walking to reach ${m.targetCount} steps.';
      case MissionType.puzzle: return 'Open the mission to answer the quiz.';
      case MissionType.escort: return 'Reach ${lm?.name}, then continue to the destination.';
      default: return 'Follow the marker to ${lm?.name ?? 'your destination'}.';
    }
  }

  void _completeMission(Mission m) {
    if (profile.completedMissions.contains(m.id) && !m.isDaily && !m.isWeekly) return;
    profile.completedMissions.add(m.id);
    profile.missionsCompleted++;
    _grant(m.rewardCoins, m.rewardXp);
    _grantRewardItem(m.rewardItemId);

    // weekly progress
    if (!m.isWeekly) {
      profile.weeklyProgress++;
      final w = weeklyMission;
      if (w != null && !profile.completedMissions.contains(w.id) &&
          profile.weeklyProgress >= w.targetCount) {
        _completeMission(w);
      }
    }

    activeMissionId = null;
    engineSend?.call('clearWaypoint', {});
    engineSend?.call('photoMode', {'on': false});

    _rahino('Mission complete! ${m.title} ✓', emote: 'celebrate');
    onMissionComplete?.call(m);
    onToast?.call('Mission complete: +${m.rewardCoins}🪙 +${m.rewardXp} XP', icon: '✅');

    _evaluateAchievements();
    _submitScore();
    _markDirty();
    notifyListeners();
  }

  void answerQuiz(Mission m, int index) {
    if (m.type != MissionType.puzzle) return;
    if (index == m.quizAnswerIndex) {
      _completeMission(m);
    } else {
      onToast?.call('Not quite — try again!', icon: '❌');
      _rahino('Hmm, that\'s not it. Give it another think!');
    }
  }

  // ===========================================================================
  // ENGINE EVENT ENTRY POINTS
  // ===========================================================================
  void onCoinCollected() {
    profile.coins++;
    profile.coinsCollected++;
    _grantXpSilent(2);
    final m = activeMission;
    if (m != null && (m.type == MissionType.collectCoins || m.type == MissionType.souvenir)) {
      activeProgress++;
      if (activeProgress >= m.targetCount) _completeMission(m);
    }
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
  }

  void onChestOpened() {
    profile.chestsOpened++;
    final bonus = 25 + Random().nextInt(40);
    _grant(bonus, 20);
    onToast?.call('Chest opened! +$bonus🪙', icon: '🧰');
    final m = activeMission;
    if (m != null && (m.type == MissionType.chests || m.type == MissionType.artifact)) {
      activeProgress++;
      if (activeProgress >= m.targetCount) _completeMission(m);
    }
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
  }

  void onLandmarkDiscovered(String id) {
    final isNew = profile.discoveredLandmarks.add(id);
    if (isNew) {
      _grant(20, 30);
      final lm = landmarkById(id);
      onToast?.call('Discovered ${lm?.name ?? id}! +20🪙 +30 XP', icon: lm?.icon ?? '📍');
    }
    _landmarkReached(id);
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
  }

  void onWaypointReached(String id) => _landmarkReached(id);

  void _landmarkReached(String id) {
    final m = activeMission;
    if (m == null) return;
    switch (m.type) {
      case MissionType.visit:
      case MissionType.museum:
      case MissionType.secret:
      case MissionType.food:
      case MissionType.transport:
      case MissionType.deliver:
        if (m.targetLandmarkId == id) _completeMission(m);
        break;
      case MissionType.escort:
        if (_escortStage == 0 && m.targetLandmarkId == id) {
          _escortStage = 1;
          engineSend?.call('setWaypoint', {'id': m.secondaryLandmarkId});
          _rahino('Good — now to ${landmarkById(m.secondaryLandmarkId ?? '')?.name ?? 'the destination'}.', emote: 'point');
          notifyListeners();
        } else if (_escortStage == 1 && m.secondaryLandmarkId == id) {
          _completeMission(m);
        }
        break;
      default:
        break;
    }
  }

  void onPhotoTaken(String id) {
    profile.photosTaken++;
    _grant(10, 15);
    final m = activeMission;
    if (m != null && m.type == MissionType.photo && m.targetLandmarkId == id) {
      _completeMission(m);
    }
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
  }

  /// Returns a dialogue line for the UI to show.
  String onNpcInteract(String id, String kind) {
    profile.npcsTalked++;
    _grantXpSilent(5);
    final m = activeMission;
    if (m != null && m.type == MissionType.talk && m.npcKind == kind) {
      _completeMission(m);
    }
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
    return _dialogueFor(kind);
  }

  void onPosition(double x, double z) {
    if (_lastX != null) {
      final d = sqrt(pow(x - _lastX!, 2) + pow(z - _lastZ!, 2));
      if (d < 40) _stepAccum += d;
    }
    _lastX = x;
    _lastZ = z;
    if (_stepAccum >= 1) {
      final s = _stepAccum.floor();
      _stepAccum -= s;
      profile.distanceWalked += s;
      final m = activeMission;
      if (m != null && m.type == MissionType.walk) {
        activeProgress = profile.distanceWalked.floor();
        if (activeProgress >= m.targetCount) _completeMission(m);
      }
      _markDirty();
    }
  }

  // ===========================================================================
  // ECONOMY & LEVELING
  // ===========================================================================
  void _grant(int coins, int xp) {
    profile.coins += coins;
    _grantXpSilent(xp);
  }

  void _grantXpSilent(int xp) {
    profile.xp += xp;
    while (profile.xp >= profile.xpToNext) {
      profile.xp -= profile.xpToNext;
      profile.level++;
      profile.coins += profile.level * 10;
      onLevelUp?.call(profile.level);
      _rahino('Level up! You are now level ${profile.level}! 🎉', emote: 'celebrate');
      _evaluateAchievements();
    }
  }

  void _grantRewardItem(String? id) {
    if (id == null) return;
    if (id == 'mystery_box') {
      final r = openMysteryBox();
      onToast?.call('Mystery Box: $r', icon: '🎁');
    } else if (id.startsWith('collectible:') || id.startsWith('badge:')) {
      if (!profile.badges.contains(id)) profile.badges.add(id);
      onToast?.call('New collectible: ${id.split(':').last}', icon: '💎');
    }
  }

  String openMysteryBox() {
    final roll = Random().nextInt(100);
    if (roll < 45) {
      final c = 30 + Random().nextInt(70);
      profile.coins += c;
      return '+$c coins';
    } else if (roll < 75) {
      profile.xp += 50;
      _grantXpSilent(0);
      return '+50 XP';
    } else if (roll < 90) {
      profile.luckyWheelTickets++;
      return 'Lucky Wheel ticket';
    } else {
      profile.treasureMaps++;
      return 'Treasure map';
    }
  }

  // ===========================================================================
  // SHOP
  // ===========================================================================
  bool canAfford(ShopItem item) => profile.coins >= item.price;
  bool isOwned(ShopItem item) => profile.ownedItems.contains(item.id);

  bool buyItem(ShopItem item) {
    if (item.consumable) {
      if (profile.coins < item.price) return false;
      profile.coins -= item.price;
      if (item.id == 'wheel_ticket') profile.luckyWheelTickets++;
      if (item.id == 'treasure_map') profile.treasureMaps++;
      onToast?.call('Purchased ${item.name}', icon: item.icon);
      _evaluateAchievements();
      _markDirty();
      notifyListeners();
      return true;
    }
    if (profile.ownedItems.contains(item.id)) {
      equipItem(item);
      return true;
    }
    if (profile.coins < item.price) return false;
    profile.coins -= item.price;
    profile.ownedItems.add(item.id);
    onToast?.call('Unlocked ${item.name}!', icon: item.icon);
    equipItem(item);
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
    return true;
  }

  void equipItem(ShopItem item) {
    if (item.cosmetic == null) return;
    final type = item.cosmetic!['type'] as String?;
    if (type == 'emote') {
      engineSend?.call('rahinoEmote', {'emote': item.cosmetic!['emote']});
    } else {
      profile.equipped[item.category.name] = item.id;
      engineSend?.call('setCosmetic', Map<String, dynamic>.from(item.cosmetic!));
    }
    _markDirty();
    notifyListeners();
  }

  // ===========================================================================
  // LIVE-OPS: daily login, daily reward, lucky wheel
  // ===========================================================================
  void _checkLiveOps(DateTime now) {
    final today = _dateStr(now);
    if (profile.lastLoginDate != today) {
      final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
      profile.loginStreak = (profile.lastLoginDate == yesterday) ? profile.loginStreak + 1 : 1;
      profile.lastLoginDate = today;
    }
    // weekly reset
    final wk = '${now.year}-${_weekOf(now)}';
    if (profile.weeklyResetDate != wk) {
      profile.weeklyResetDate = wk;
      profile.weeklyProgress = 0;
    }
    _markDirty();
  }

  /// Claim daily login reward; returns the reward text or null if already claimed.
  String? claimDaily() {
    final today = _dateStr(DateTime.now());
    if (profile.dailyClaimedDate == today) return null;
    profile.dailyClaimedDate = today;
    final streak = profile.loginStreak.clamp(1, 7);
    final coins = 30 * streak;
    profile.coins += coins;
    String extra = '';
    if (streak % 7 == 0) {
      profile.luckyWheelTickets++;
      extra = ' + Lucky Wheel ticket';
    }
    _grantXpSilent(20);
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
    return '+$coins🪙 (day $streak streak)$extra';
  }

  /// Spin the Lucky Wheel. Returns reward text, or null if no tickets.
  String? spinLuckyWheel() {
    if (profile.luckyWheelTickets <= 0) return null;
    profile.luckyWheelTickets--;
    final prizes = <String>[
      'coins_100', 'coins_50', 'xp_100', 'ticket', 'map', 'coins_250', 'mystery'
    ];
    final p = prizes[Random().nextInt(prizes.length)];
    String text;
    switch (p) {
      case 'coins_100': profile.coins += 100; text = '+100 coins'; break;
      case 'coins_50': profile.coins += 50; text = '+50 coins'; break;
      case 'coins_250': profile.coins += 250; text = '+250 coins!'; break;
      case 'xp_100': _grantXpSilent(100); text = '+100 XP'; break;
      case 'ticket': profile.luckyWheelTickets++; text = 'Another ticket!'; break;
      case 'map': profile.treasureMaps++; text = 'Treasure map'; break;
      default: text = openMysteryBox(); break;
    }
    _evaluateAchievements();
    _markDirty();
    notifyListeners();
    return text;
  }

  void fastTravel(String landmarkId) {
    final discovered = profile.discoveredLandmarks.contains(landmarkId);
    final vip = profile.ownedItems.contains('fasttravel_pass');
    if (!discovered && !vip) {
      onToast?.call('Discover this place first (or get the VIP Travel Pass).', icon: '🔒');
      return;
    }
    engineSend?.call('fastTravel', {'id': landmarkId});
  }

  // ===========================================================================
  // ACHIEVEMENTS
  // ===========================================================================
  void _evaluateAchievements() {
    for (final a in kAchievements) {
      if (profile.unlockedAchievements.contains(a.id)) continue;
      if (_metric(a.metric) >= a.threshold) {
        profile.unlockedAchievements.add(a.id);
        profile.coins += a.rewardCoins;
        if (a.rewardTitle != null) profile.title = a.rewardTitle!;
        if (!profile.badges.contains('badge:${a.id}')) profile.badges.add('badge:${a.id}');
        onAchievement?.call(a);
      }
    }
  }

  int _metric(AchievementMetric m) {
    switch (m) {
      case AchievementMetric.level: return profile.level;
      case AchievementMetric.coinsCollected: return profile.coinsCollected;
      case AchievementMetric.missionsCompleted: return profile.missionsCompleted;
      case AchievementMetric.landmarksDiscovered: return profile.discoveredLandmarks.length;
      case AchievementMetric.chestsOpened: return profile.chestsOpened;
      case AchievementMetric.photosTaken: return profile.photosTaken;
      case AchievementMetric.npcsTalked: return profile.npcsTalked;
      case AchievementMetric.loginStreak: return profile.loginStreak;
      case AchievementMetric.distanceWalked: return profile.distanceWalked.floor();
      case AchievementMetric.itemsOwned: return profile.ownedItems.length;
    }
  }

  // ===========================================================================
  // ENGINE HELPERS
  // ===========================================================================
  void setWeather(String w) => engineSend?.call('setWeather', {'weather': w});
  void setTime(double hour) => engineSend?.call('setTime', {'hour': hour});

  void _rahino(String text, {String? emote}) {
    engineSend?.call('rahinoSay', {'text': text});
    if (emote != null) engineSend?.call('rahinoEmote', {'emote': emote});
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================
  void _markDirty() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1200), () {
      _save.save(profile);
      if (_cloud.enabled) _cloud.uploadSave(profile.toJson());
    });
  }

  Future<void> saveNow() async {
    await _save.save(profile);
    if (_cloud.enabled) {
      await _cloud.uploadSave(profile.toJson());
      _submitScore();
    }
  }

  void _submitScore() {
    if (!_cloud.enabled) return;
    _cloud.submitScore(
      name: profile.name,
      score: profile.missionsCompleted * 100 + profile.coinsCollected,
      level: profile.level,
    );
  }

  Future<void> resetSave() async {
    await _save.reset();
    profile = PlayerProfile();
    final now = DateTime.now();
    dailyMission = dailyMissionFor(now, allMissions);
    weeklyMission = weeklyMissionFor(now);
    activeMissionId = null;
    _checkLiveOps(now);
    notifyListeners();
  }

  // ---- utils ----
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _weekOf(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    return ((d.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

  String _dialogueFor(String kind) {
    const lines = {
      'Tourist': 'Wow, Istanbul is amazing! Have you seen the Blue Mosque yet?',
      'Hotel Staff': 'Welcome! Check-in is this way. Need help with your bags?',
      'Taxi Driver': 'Nereye? Hop in, I know every shortcut in this city!',
      'Restaurant Owner': 'Buyrun! Try our fresh balık ekmek, best in town!',
      'Police': 'Everything okay? Stay safe and enjoy the city.',
      'Airport Staff': 'Welcome to Istanbul! Your adventure starts here.',
      'Street Vendor': 'Simit! Fresh simit! Only the best sesame rings here.',
      'Boat Captain': 'The Bosphorus is calm today — perfect for a ferry ride.',
      'Museum Guide': 'This monument has over 1500 years of history. Shall I tell you more?',
    };
    return lines[kind] ?? 'Merhaba! Welcome to Istanbul.';
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
