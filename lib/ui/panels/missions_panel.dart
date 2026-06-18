import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mission.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'sheet.dart';

class MissionsPanel extends StatefulWidget {
  const MissionsPanel({super.key});

  @override
  State<MissionsPanel> createState() => _MissionsPanelState();
}

class _MissionsPanelState extends State<MissionsPanel> {
  String _filter = 'all';

  static const _filters = <String, String>{
    'all': '🌟 All',
    'visit': '📍 Visit',
    'photo': '📷 Photo',
    'collectCoins': '🪙 Coins',
    'talk': '💬 Talk',
    'escort': '🚶 Escort',
    'puzzle': '🧩 Quiz',
    'artifact': '🏺 Treasure',
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final all = game.allMissions;
    final list = all.where((m) {
      if (_filter == 'all') return true;
      return m.type.name == _filter;
    }).toList();
    // incomplete first
    list.sort((a, b) {
      final ca = game.isMissionCompleted(a.id) ? 1 : 0;
      final cb = game.isMissionCompleted(b.id) ? 1 : 0;
      return ca - cb;
    });

    return Sheet(
      title: 'Missions',
      icon: '📜',
      child: Column(
        children: [
          // featured: daily + weekly
          if (game.dailyMission != null)
            _MissionTile(mission: game.dailyMission!, featured: true),
          if (game.weeklyMission != null)
            _WeeklyTile(mission: game.weeklyMission!),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _filter == e.key,
                          onSelected: (_) => setState(() => _filter = e.key),
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: _filter == e.key ? AppColors.navy : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppColors.navy2,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _MissionTile(mission: list[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission, this.featured = false});
  final Mission mission;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final done = game.isMissionCompleted(mission.id);
    final active = game.activeMissionId == mission.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: featured ? AppColors.ember.withOpacity(0.18) : AppColors.navy2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.gold : Colors.white12,
          width: active ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Text(mission.icon, style: const TextStyle(fontSize: 26)),
        title: Text(mission.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? Colors.white38 : Colors.white,
            )),
        subtitle: Text(
          mission.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: done
            ? const Icon(Icons.check_circle, color: AppColors.teal)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('+${mission.rewardCoins}🪙', style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('+${mission.rewardXp} XP', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
        onTap: done ? null : () => _start(context, game, mission),
      ),
    );
  }

  void _start(BuildContext context, GameState game, Mission m) {
    if (m.type == MissionType.puzzle) {
      _quiz(context, game, m);
      return;
    }
    game.setActiveMission(m);
    Navigator.of(context).maybePop();
  }

  void _quiz(BuildContext context, GameState game, Mission m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navy2,
        title: Text('🧩 ${m.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.quizQuestion ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ...List.generate(m.quizOptions?.length ?? 0, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      game.answerQuiz(m, i);
                    },
                    child: Text(m.quizOptions![i]),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTile extends StatelessWidget {
  const _WeeklyTile({required this.mission});
  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final progress = (game.profile.weeklyProgress / mission.targetCount).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.teal.withOpacity(0.25), AppColors.navy2]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('+${mission.rewardCoins}🪙', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.teal,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 4),
          Text('${game.profile.weeklyProgress}/${mission.targetCount} missions this week',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
