import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/achievements_data.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'sheet.dart';

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final p = game.profile;

    return Sheet(
      title: 'Profile',
      icon: '👤',
      child: ListView(
        children: [
          // header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.ember.withOpacity(0.4), AppColors.navy2]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(child: Text('🦏', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                        child: Text(p.title, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      Text('Level ${p.level}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: game.xpFraction,
                          minHeight: 7,
                          color: AppColors.gold,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Text('${p.xp}/${p.xpToNext} XP', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Stats'),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              _stat('🪙', '${p.coins}', 'Coins'),
              _stat('💰', '${p.coinsCollected}', 'Earned'),
              _stat('📜', '${p.missionsCompleted}', 'Missions'),
              _stat('🗺️', '${p.discoveredLandmarks.length}/22', 'Discovered'),
              _stat('🧰', '${p.chestsOpened}', 'Chests'),
              _stat('📷', '${p.photosTaken}', 'Photos'),
              _stat('💬', '${p.npcsTalked}', 'Chats'),
              _stat('👟', '${p.distanceWalked.floor()}', 'Steps'),
              _stat('🔥', '${p.loginStreak}d', 'Streak'),
              _stat('🎡', '${p.luckyWheelTickets}', 'Tickets'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Achievements (${p.unlockedAchievements.length}/${kAchievements.length})'),
          ...kAchievements.map((a) {
            final unlocked = p.unlockedAchievements.contains(a.id);
            return Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: ListTile(
                leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
                title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(a.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: unlocked
                    ? const Icon(Icons.verified, color: AppColors.teal)
                    : const Icon(Icons.lock_outline, color: Colors.white30),
              ),
            );
          }),
          const SizedBox(height: 16),
          _SectionTitle(game.cloudEnabled ? 'Global Leaderboard' : 'Leaderboard'),
          const _Leaderboard(),
          const SizedBox(height: 10),
          Text(
            game.cloudEnabled
                ? 'Live global ranks via your cloud backend.'
                : 'Local leaderboard. Set a backend URL (lib/config.dart) to enable '
                    'cloud saves & global ranks.',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _stat(String icon, String value, String label) => Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.navy2.withOpacity(0.6), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold)),
        ),
      );
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  List<LeaderboardEntry> _local(GameState game) {
    final me = game.profile;
    final list = <LeaderboardEntry>[
      LeaderboardEntry(name: 'Selin', score: (me.level + 4) * 220, level: me.level + 4),
      LeaderboardEntry(name: 'Mehmet', score: (me.level + 2) * 210, level: me.level + 2),
      LeaderboardEntry(name: me.name, score: me.missionsCompleted * 100 + me.coinsCollected, level: me.level, isMe: true),
      LeaderboardEntry(name: 'Ayşe', score: me.level * 150, level: me.level),
      LeaderboardEntry(name: 'Can', score: me.level * 120, level: me.level),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    if (!game.cloudEnabled) return _list(_local(game));
    return FutureBuilder<List<LeaderboardEntry>>(
      future: game.fetchLeaderboard(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          );
        }
        final data = (snap.data == null || snap.data!.isEmpty) ? _local(game) : snap.data!;
        return _list(data);
      },
    );
  }

  Widget _list(List<LeaderboardEntry> entries) {
    return Column(
      children: List.generate(entries.length, (i) {
        final r = entries[i];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: r.isMe ? AppColors.gold.withOpacity(0.2) : AppColors.navy2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: r.isMe ? AppColors.gold : Colors.transparent),
          ),
          child: Row(
            children: [
              Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold)),
              const SizedBox(width: 12),
              Text(r.name, style: TextStyle(fontWeight: r.isMe ? FontWeight.w900 : FontWeight.w600)),
              const SizedBox(width: 6),
              Text('Lv${r.level}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              Text('${r.score} pts', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }),
    );
  }
}
