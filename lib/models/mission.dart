/// Mission categories drive the icon, tracking logic and how the engine is told
/// to set waypoints / photo mode etc.
enum MissionType {
  visit,        // reach a landmark
  photo,        // take a photo of a landmark
  collectCoins, // collect N coins
  chests,       // open N hidden chests
  talk,         // talk to an NPC kind
  deliver,      // deliver luggage/item to a landmark
  escort,       // guide a tourist between two landmarks
  transport,    // use a ferry/metro terminal
  food,         // find a local food spot
  museum,       // visit a museum/monument
  souvenir,     // collect souvenirs (coins near a market)
  walk,         // walking challenge (distance)
  puzzle,       // answer a travel quiz
  artifact,     // find a hidden historical artifact (chest near monument)
  secret,       // discover a secret/hidden location
  daily,        // daily challenge
  weekly,       // weekly objective
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final String? targetLandmarkId;
  final String? secondaryLandmarkId; // escort destination
  final String? npcKind;
  final int targetCount;
  final int rewardCoins;
  final int rewardXp;
  final String? rewardItemId; // collectible / badge / mystery_box
  final int difficulty;       // 1..3
  final bool isDaily;
  final bool isWeekly;
  final String? quizQuestion;
  final List<String>? quizOptions;
  final int quizAnswerIndex;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.targetLandmarkId,
    this.secondaryLandmarkId,
    this.npcKind,
    this.targetCount = 1,
    required this.rewardCoins,
    required this.rewardXp,
    this.rewardItemId,
    this.difficulty = 1,
    this.isDaily = false,
    this.isWeekly = false,
    this.quizQuestion,
    this.quizOptions,
    this.quizAnswerIndex = 0,
  });

  String get icon {
    switch (type) {
      case MissionType.visit: return '📍';
      case MissionType.photo: return '📷';
      case MissionType.collectCoins: return '🪙';
      case MissionType.chests: return '🧰';
      case MissionType.talk: return '💬';
      case MissionType.deliver: return '🧳';
      case MissionType.escort: return '🚶';
      case MissionType.transport: return '⛴️';
      case MissionType.food: return '🍢';
      case MissionType.museum: return '🏛️';
      case MissionType.souvenir: return '🛍️';
      case MissionType.walk: return '👟';
      case MissionType.puzzle: return '🧩';
      case MissionType.artifact: return '🏺';
      case MissionType.secret: return '🔑';
      case MissionType.daily: return '🎁';
      case MissionType.weekly: return '📅';
    }
  }
}
