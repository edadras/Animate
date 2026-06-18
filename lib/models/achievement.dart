enum AchievementMetric {
  level,
  coinsCollected,
  missionsCompleted,
  landmarksDiscovered,
  chestsOpened,
  photosTaken,
  npcsTalked,
  loginStreak,
  distanceWalked,
  itemsOwned,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementMetric metric;
  final int threshold;
  final int rewardCoins;
  final String? rewardTitle; // unlockable profile title

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.metric,
    required this.threshold,
    this.rewardCoins = 50,
    this.rewardTitle,
  });
}
