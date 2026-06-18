import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(28),
                decoration: AppTheme.glassCard(radius: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🦏', style: TextStyle(fontSize: 64)),
                    ShaderMask(
                      shaderCallback: (r) => AppTheme.goldGradient.createShader(r),
                      child: const Text('RAHINO',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                    ),
                    const Text('Istanbul Treasure Hunt',
                        style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    const Text(
                      'A 3D travel adventure across Istanbul. Explore landmarks, complete missions, collect treasures and level up — guided by Rahino.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _StatRow(game: game),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        ),
                        child: Text(game.profile.level > 1 ? '▶  Continue Adventure' : '▶  Start Adventure'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _howTo(context),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                            child: const Text('How to Play'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _resetConfirm(context, game),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.ember),
                            child: const Text('Reset Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _howTo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navy2,
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Text(
            '• Move with the on-screen joystick (WASD on desktop).\n'
            '• Tap RUN to sprint, JUMP to hop, and ✋ to interact.\n'
            '• Walk near landmarks to discover them and earn XP.\n'
            '• Collect glowing coins and open hidden chests.\n'
            '• Open 📜 Missions to pick adventures — Rahino sets a waypoint.\n'
            '• Photo missions: enable photo mode, frame the landmark, snap 📷.\n'
            '• Spend coins in 🛍️ Shop on outfits, pets, Rahino costumes & more.\n'
            '• Come back daily for login rewards, the Lucky Wheel & new challenges.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it!'))],
      ),
    );
  }

  void _resetConfirm(BuildContext context, GameState game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navy2,
        title: const Text('Reset Save?'),
        content: const Text('This will erase all progress, coins, levels and unlocks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              game.resetSave();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.ember)),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    Widget chip(String icon, String value, String label) => Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        chip('🏅', 'Lv ${game.level}', game.profile.title),
        chip('🪙', '${game.coins}', 'Coins'),
        chip('🗺️', '${game.profile.discoveredLandmarks.length}/22', 'Discovered'),
        chip('🔥', '${game.profile.loginStreak}d', 'Streak'),
      ],
    );
  }
}
