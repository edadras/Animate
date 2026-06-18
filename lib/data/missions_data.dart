import 'dart:math';
import '../models/mission.dart';
import 'landmarks_data.dart';

/// Travel-quiz pool used by puzzle missions and the "answer travel questions"
/// daily challenge.
const List<Map<String, dynamic>> kQuizzes = [
  {'q': 'Which two continents does Istanbul span?', 'o': ['Europe & Asia', 'Africa & Asia', 'Europe & Africa', 'Asia & Oceania'], 'a': 0},
  {'q': 'What strait runs through Istanbul?', 'o': ['Bosphorus', 'Gibraltar', 'Malacca', 'Hormuz'], 'a': 0},
  {'q': 'Hagia Sophia was originally built as a…', 'o': ['Cathedral', 'Palace', 'Bazaar', 'Lighthouse'], 'a': 0},
  {'q': 'The Blue Mosque is famous for tiles of which colour?', 'o': ['Blue', 'Green', 'Red', 'Gold'], 'a': 0},
  {'q': 'What food is Ortaköy famous for?', 'o': ['Kumpir', 'Sushi', 'Pizza', 'Tacos'], 'a': 0},
  {'q': 'The Grand Bazaar has roughly how many shops?', 'o': ['4,000', '40', '400', '40,000'], 'a': 0},
  {'q': 'A "balık ekmek" is a sandwich made with…', 'o': ['Fish', 'Lamb', 'Cheese', 'Chicken'], 'a': 0},
  {'q': 'Which tower sits on a tiny Bosphorus islet?', 'o': ["Maiden's Tower", 'Galata Tower', 'Eiffel Tower', 'Pisa Tower'], 'a': 0},
  {'q': 'İstiklal Street is famous for its nostalgic red…', 'o': ['Tram', 'Bus', 'Taxi', 'Ferry'], 'a': 0},
  {'q': 'The Spice Bazaar is also called the … Bazaar.', 'o': ['Egyptian', 'Persian', 'Roman', 'Greek'], 'a': 0},
  {'q': 'Which drink is traditionally served in tulip-shaped glasses?', 'o': ['Turkish tea', 'Cola', 'Coffee latte', 'Lemonade'], 'a': 0},
  {'q': 'Gülhane Park was once the garden of which palace?', 'o': ['Topkapı', 'Versailles', 'Buckingham', 'Alhambra'], 'a': 0},
];

/// Build the full catalogue of missions (hundreds), deterministically.
List<Mission> buildAllMissions() {
  final List<Mission> out = [];
  final monuments = kLandmarks.where((l) => l.type == 'monument' || l.type == 'tower').toList();
  final transports = kLandmarks.where((l) => l.type == 'transport').toList();

  // 1) Visit every landmark.
  for (final l in kLandmarks) {
    out.add(Mission(
      id: 'visit_${l.id}',
      title: 'Discover ${l.name}',
      description: 'Travel to ${l.name} in ${l.district} and discover it.',
      type: MissionType.visit,
      targetLandmarkId: l.id,
      rewardCoins: 30, rewardXp: 25, difficulty: 1,
    ));
  }

  // 2) Photograph monuments & towers.
  for (final l in monuments) {
    out.add(Mission(
      id: 'photo_${l.id}',
      title: 'Photograph ${l.name}',
      description: 'Frame ${l.name} in photo mode and take the perfect shot.',
      type: MissionType.photo,
      targetLandmarkId: l.id,
      rewardCoins: 45, rewardXp: 40, rewardItemId: 'collectible:postcard', difficulty: 2,
    ));
  }

  // 3) Visit museums/monuments (culture).
  for (final l in monuments) {
    out.add(Mission(
      id: 'museum_${l.id}',
      title: 'Cultural Visit: ${l.name}',
      description: 'Step inside ${l.name} and learn its history.',
      type: MissionType.museum,
      targetLandmarkId: l.id,
      rewardCoins: 40, rewardXp: 45, difficulty: 2,
    ));
  }

  // 4) Talk to each kind of NPC.
  const npcKinds = ['Tourist', 'Hotel Staff', 'Taxi Driver', 'Restaurant Owner', 'Police', 'Airport Staff', 'Street Vendor', 'Boat Captain', 'Museum Guide'];
  for (final k in npcKinds) {
    out.add(Mission(
      id: 'talk_${k.replaceAll(' ', '_').toLowerCase()}',
      title: 'Chat with a $k',
      description: 'Find a $k somewhere in the city and have a chat.',
      type: MissionType.talk,
      npcKind: k,
      rewardCoins: 25, rewardXp: 20, difficulty: 1,
    ));
  }

  // 5) Help tourists reach their hotel / deliver luggage (transport+hotel).
  final hotels = kLandmarks.where((l) => l.type == 'hotel').toList();
  for (final h in hotels) {
    out.add(Mission(
      id: 'hotel_${h.id}',
      title: 'Help a Tourist to ${h.name}',
      description: 'A lost traveller needs to reach ${h.name}. Guide them there.',
      type: MissionType.deliver,
      targetLandmarkId: h.id,
      rewardCoins: 50, rewardXp: 45, difficulty: 2,
    ));
    out.add(Mission(
      id: 'luggage_${h.id}',
      title: 'Deliver Forgotten Luggage',
      description: 'Someone left their suitcase behind — bring it to ${h.name}.',
      type: MissionType.deliver,
      targetLandmarkId: h.id,
      rewardCoins: 55, rewardXp: 50, rewardItemId: 'mystery_box', difficulty: 2,
    ));
  }

  // 6) Escort missions between landmark pairs (generates many).
  final rng = Random(42);
  final pool = kLandmarks.toList();
  for (final a in pool) {
    // pick a few distinct destinations for variety
    final picks = (pool.toList()..shuffle(rng)).where((b) => b.id != a.id).take(3);
    for (final b in picks) {
      out.add(Mission(
        id: 'escort_${a.id}_${b.id}',
        title: 'Escort: ${a.name} → ${b.name}',
        description: 'Walk a visitor from ${a.name} to ${b.name} safely.',
        type: MissionType.escort,
        targetLandmarkId: a.id,
        secondaryLandmarkId: b.id,
        rewardCoins: 60, rewardXp: 55, difficulty: 3,
      ));
    }
  }

  // 7) Public transport challenges.
  for (final t in transports) {
    out.add(Mission(
      id: 'transport_${t.id}',
      title: 'Use ${t.name}',
      description: 'Navigate using public transport — reach ${t.name}.',
      type: MissionType.transport,
      targetLandmarkId: t.id,
      rewardCoins: 35, rewardXp: 30, difficulty: 1,
    ));
  }

  // 8) Find local food.
  final foods = kLandmarks.where((l) => l.type == 'restaurant' || l.type == 'cafe' || l.type == 'market').toList();
  for (final f in foods) {
    out.add(Mission(
      id: 'food_${f.id}',
      title: 'Taste Istanbul at ${f.name}',
      description: 'Find a local delicacy near ${f.name}.',
      type: MissionType.food,
      targetLandmarkId: f.id,
      rewardCoins: 40, rewardXp: 35, rewardItemId: 'collectible:simit', difficulty: 1,
    ));
  }

  // 9) Souvenir hunts at markets.
  final markets = kLandmarks.where((l) => l.type == 'market').toList();
  for (final m in markets) {
    out.add(Mission(
      id: 'souvenir_${m.id}',
      title: 'Souvenir Hunt: ${m.name}',
      description: 'Collect 8 coins worth of souvenirs around ${m.name}.',
      type: MissionType.souvenir,
      targetLandmarkId: m.id,
      targetCount: 8,
      rewardCoins: 50, rewardXp: 45, difficulty: 2,
    ));
  }

  // 10) Hidden artifacts near monuments (chests).
  for (final l in monuments) {
    out.add(Mission(
      id: 'artifact_${l.id}',
      title: 'Find a Hidden Artifact',
      description: 'A historical artifact is hidden near ${l.name}. Open a chest to recover it.',
      type: MissionType.artifact,
      targetLandmarkId: l.id,
      rewardCoins: 70, rewardXp: 60, rewardItemId: 'mystery_box', difficulty: 3,
    ));
  }

  // 11) Secret locations (hidden-type landmarks).
  final secrets = kLandmarks.where((l) => l.type == 'hidden' || l.type == 'viewpoint').toList();
  for (final s in secrets) {
    out.add(Mission(
      id: 'secret_${s.id}',
      title: 'Discover a Secret Spot',
      description: 'Locals whisper about ${s.name}. Find this hidden gem.',
      type: MissionType.secret,
      targetLandmarkId: s.id,
      rewardCoins: 65, rewardXp: 55, rewardItemId: 'collectible:hidden_key', difficulty: 3,
    ));
  }

  // 12) Coin collection tiers.
  for (var i = 0; i < 6; i++) {
    final n = 10 + i * 15;
    out.add(Mission(
      id: 'coins_tier_$i',
      title: 'Treasure Hunter $i',
      description: 'Collect $n coins around the city.',
      type: MissionType.collectCoins,
      targetCount: n,
      rewardCoins: 20 + i * 15, rewardXp: 30 + i * 20, difficulty: (i ~/ 2) + 1,
    ));
  }

  // 13) Chest hunts.
  for (var i = 1; i <= 4; i++) {
    out.add(Mission(
      id: 'chests_tier_$i',
      title: 'Chest Seeker $i',
      description: 'Open ${i * 2} hidden chests.',
      type: MissionType.chests,
      targetCount: i * 2,
      rewardCoins: 40 * i, rewardXp: 40 * i, rewardItemId: i == 4 ? 'mystery_box' : null, difficulty: 2,
    ));
  }

  // 14) Walking challenges.
  for (var i = 1; i <= 5; i++) {
    out.add(Mission(
      id: 'walk_tier_$i',
      title: 'Walking Challenge $i',
      description: 'Walk ${i * 300} steps exploring Istanbul.',
      type: MissionType.walk,
      targetCount: i * 300,
      rewardCoins: 25 * i, rewardXp: 25 * i, difficulty: 1,
    ));
  }

  // 15) Travel quizzes (puzzles).
  for (var i = 0; i < kQuizzes.length; i++) {
    final q = kQuizzes[i];
    out.add(Mission(
      id: 'quiz_$i',
      title: 'Travel Quiz #${i + 1}',
      description: 'Answer a question about Istanbul.',
      type: MissionType.puzzle,
      rewardCoins: 35, rewardXp: 40, difficulty: 2,
      quizQuestion: q['q'] as String,
      quizOptions: (q['o'] as List).map((e) => e.toString()).toList(),
      quizAnswerIndex: q['a'] as int,
    ));
  }

  return out;
}

/// Deterministic daily challenge for a given date.
Mission dailyMissionFor(DateTime date, List<Mission> all) {
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final pickable = all.where((m) => !m.isWeekly && m.type != MissionType.escort).toList();
  final m = pickable[seed % pickable.length];
  return Mission(
    id: 'daily_${seed}_${m.id}',
    title: 'Daily: ${m.title}',
    description: m.description,
    type: MissionType.daily,
    targetLandmarkId: m.targetLandmarkId,
    secondaryLandmarkId: m.secondaryLandmarkId,
    npcKind: m.npcKind,
    targetCount: m.targetCount,
    rewardCoins: m.rewardCoins + 40,
    rewardXp: m.rewardXp + 30,
    rewardItemId: 'mystery_box',
    isDaily: true,
    quizQuestion: m.quizQuestion,
    quizOptions: m.quizOptions,
    quizAnswerIndex: m.quizAnswerIndex,
  );
}

/// Deterministic weekly objective (collect coins) for the week of [date].
Mission weeklyMissionFor(DateTime date) {
  final week = _weekNumber(date);
  return Mission(
    id: 'weekly_${date.year}_$week',
    title: 'Weekly Quest: Grand Explorer',
    description: 'Complete 7 missions this week to earn a big reward.',
    type: MissionType.weekly,
    targetCount: 7,
    rewardCoins: 300,
    rewardXp: 250,
    rewardItemId: 'mystery_box',
    isWeekly: true,
  );
}

int _weekNumber(DateTime d) {
  final firstDay = DateTime(d.year, 1, 1);
  return ((d.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
}
