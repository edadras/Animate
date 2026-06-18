import '../models/achievement.dart';

const List<Achievement> kAchievements = [
  // Levels
  Achievement(id: 'lvl5', name: 'Getting Around', description: 'Reach level 5.', icon: '🌟', metric: AchievementMetric.level, threshold: 5, rewardCoins: 100, rewardTitle: 'Wanderer'),
  Achievement(id: 'lvl10', name: 'Seasoned Traveller', description: 'Reach level 10.', icon: '⭐', metric: AchievementMetric.level, threshold: 10, rewardCoins: 200, rewardTitle: 'Voyager'),
  Achievement(id: 'lvl20', name: 'Istanbul Expert', description: 'Reach level 20.', icon: '🏆', metric: AchievementMetric.level, threshold: 20, rewardCoins: 400, rewardTitle: 'Pasha of Travel'),

  // Coins
  Achievement(id: 'coins100', name: 'Coin Collector', description: 'Collect 100 coins total.', icon: '🪙', metric: AchievementMetric.coinsCollected, threshold: 100, rewardCoins: 80),
  Achievement(id: 'coins500', name: 'Treasure Hoarder', description: 'Collect 500 coins total.', icon: '💰', metric: AchievementMetric.coinsCollected, threshold: 500, rewardCoins: 200, rewardTitle: 'Treasure Hunter'),
  Achievement(id: 'coins1000', name: 'Golden Touch', description: 'Collect 1000 coins total.', icon: '👑', metric: AchievementMetric.coinsCollected, threshold: 1000, rewardCoins: 400),

  // Missions
  Achievement(id: 'mis10', name: 'On a Mission', description: 'Complete 10 missions.', icon: '📜', metric: AchievementMetric.missionsCompleted, threshold: 10, rewardCoins: 120),
  Achievement(id: 'mis50', name: 'Mission Master', description: 'Complete 50 missions.', icon: '🎖️', metric: AchievementMetric.missionsCompleted, threshold: 50, rewardCoins: 300, rewardTitle: 'Mission Master'),
  Achievement(id: 'mis100', name: 'Legend of Istanbul', description: 'Complete 100 missions.', icon: '🏅', metric: AchievementMetric.missionsCompleted, threshold: 100, rewardCoins: 600, rewardTitle: 'Living Legend'),

  // Landmarks
  Achievement(id: 'lm5', name: 'Sightseer', description: 'Discover 5 landmarks.', icon: '📸', metric: AchievementMetric.landmarksDiscovered, threshold: 5, rewardCoins: 100),
  Achievement(id: 'lm12', name: 'City Explorer', description: 'Discover 12 landmarks.', icon: '🗺️', metric: AchievementMetric.landmarksDiscovered, threshold: 12, rewardCoins: 200, rewardTitle: 'Explorer'),
  Achievement(id: 'lm22', name: 'Istanbul Cartographer', description: 'Discover all landmarks.', icon: '🧭', metric: AchievementMetric.landmarksDiscovered, threshold: 22, rewardCoins: 500, rewardTitle: 'Cartographer'),

  // Chests
  Achievement(id: 'chest5', name: 'Treasure Seeker', description: 'Open 5 hidden chests.', icon: '🧰', metric: AchievementMetric.chestsOpened, threshold: 5, rewardCoins: 120),
  Achievement(id: 'chest15', name: 'Master Looter', description: 'Open 15 hidden chests.', icon: '💎', metric: AchievementMetric.chestsOpened, threshold: 15, rewardCoins: 300),

  // Photos
  Achievement(id: 'photo5', name: 'Shutterbug', description: 'Take 5 landmark photos.', icon: '📷', metric: AchievementMetric.photosTaken, threshold: 5, rewardCoins: 100),
  Achievement(id: 'photo15', name: 'Travel Photographer', description: 'Take 15 landmark photos.', icon: '🖼️', metric: AchievementMetric.photosTaken, threshold: 15, rewardCoins: 250, rewardTitle: 'Photographer'),

  // Social
  Achievement(id: 'npc10', name: 'Friendly Face', description: 'Talk to 10 NPCs.', icon: '💬', metric: AchievementMetric.npcsTalked, threshold: 10, rewardCoins: 100),
  Achievement(id: 'npc30', name: 'Local Hero', description: 'Talk to 30 NPCs.', icon: '🤝', metric: AchievementMetric.npcsTalked, threshold: 30, rewardCoins: 250, rewardTitle: 'Local Hero'),

  // Login streak
  Achievement(id: 'streak3', name: 'Regular Visitor', description: 'Log in 3 days in a row.', icon: '📅', metric: AchievementMetric.loginStreak, threshold: 3, rewardCoins: 100),
  Achievement(id: 'streak7', name: 'Daily Devotee', description: 'Log in 7 days in a row.', icon: '🔥', metric: AchievementMetric.loginStreak, threshold: 7, rewardCoins: 250, rewardTitle: 'Devotee'),

  // Walking
  Achievement(id: 'walk1k', name: 'Stroller', description: 'Walk 1,000 steps.', icon: '👟', metric: AchievementMetric.distanceWalked, threshold: 1000, rewardCoins: 80),
  Achievement(id: 'walk5k', name: 'Marathon Tourist', description: 'Walk 5,000 steps.', icon: '🏃', metric: AchievementMetric.distanceWalked, threshold: 5000, rewardCoins: 220),

  // Collection
  Achievement(id: 'own10', name: 'Shopper', description: 'Own 10 shop items.', icon: '🛍️', metric: AchievementMetric.itemsOwned, threshold: 10, rewardCoins: 150),
  Achievement(id: 'own20', name: 'Collector', description: 'Own 20 shop items.', icon: '💼', metric: AchievementMetric.itemsOwned, threshold: 20, rewardCoins: 350, rewardTitle: 'Collector'),
];
