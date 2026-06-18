import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../bridge/game_bridge.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'sheet.dart';

/// Daily rewards, Lucky Wheel, seasonal event and world (weather/time) controls.
class LivePanel extends StatefulWidget {
  const LivePanel({super.key, required this.bridge});
  final GameBridge bridge;

  @override
  State<LivePanel> createState() => _LivePanelState();
}

class _LivePanelState extends State<LivePanel> with SingleTickerProviderStateMixin {
  late final AnimationController _wheel =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _spinning = false;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  String _season() {
    final m = DateTime.now().month;
    if (m == 12 || m <= 2) return '❄️ Winter Snow Festival';
    if (m <= 5) return '🌷 Tulip Festival';
    if (m <= 8) return '☀️ Bosphorus Summer';
    return '🍂 Autumn Lights';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Sheet(
      title: 'Daily & Events',
      icon: '🎁',
      child: ListView(
        children: [
          // Seasonal event
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.ember, AppColors.gold]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_season(),
                          style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 16)),
                      const Text('Limited-time bonus rewards are active!',
                          style: TextStyle(color: AppColors.navy)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily reward
          _card(
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Login Reward', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Streak: ${game.profile.loginStreak} day(s) 🔥',
                              style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final claimed = game.profile.loginStreak >= day && !game.dailyRewardAvailable;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: claimed ? AppColors.teal : AppColors.navy,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            Text('D$day', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            Text('${30 * day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: game.dailyRewardAvailable
                        ? () {
                            final r = game.claimDaily();
                            if (r != null) _popup(context, 'Daily Reward!', r);
                          }
                        : null,
                    child: Text(game.dailyRewardAvailable ? 'Claim Today\'s Reward' : 'Claimed ✓ — come back tomorrow'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lucky wheel
          _card(
            child: Column(
              children: [
                const Text('🎡 Lucky Wheel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _wheel,
                  builder: (_, child) => Transform.rotate(
                    angle: _wheel.value * 2 * pi * 5,
                    child: child,
                  ),
                  child: Container(
                    width: 120, height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        AppColors.gold, AppColors.ember, AppColors.teal, AppColors.sky,
                        AppColors.gold, AppColors.ember, AppColors.teal, AppColors.gold,
                      ]),
                    ),
                    child: const Center(child: Text('🎯', style: TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tickets: ${game.profile.luckyWheelTickets} 🎫', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (game.profile.luckyWheelTickets > 0 && !_spinning)
                        ? () => _spin(context, game)
                        : null,
                    child: Text(game.profile.luckyWheelTickets > 0 ? 'Spin!' : 'No tickets — buy in Shop'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // World controls
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌦️ World', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: const {
                    'sunny': '☀️ Sunny', 'sunset': '🌇 Sunset', 'rain': '🌧️ Rain',
                    'fog': '🌫️ Fog', 'snow': '❄️ Snow',
                  }.entries.map((e) {
                    return _WeatherChip(value: e.key, label: e.value);
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Time of day', style: TextStyle(color: Colors.white70)),
                ValueListenableBuilder<double>(
                  valueListenable: widget.bridge.hour,
                  builder: (_, hour, __) => Slider(
                    value: hour.clamp(0, 24),
                    min: 0, max: 24,
                    activeColor: AppColors.gold,
                    label: '${hour.floor()}:00',
                    onChanged: (v) => game.setTime(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (game.activeMission != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => game.abandonMission(),
                icon: const Icon(Icons.flag_outlined, color: AppColors.ember),
                label: const Text('Abandon active mission', style: TextStyle(color: AppColors.ember)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _spin(BuildContext context, GameState game) async {
    setState(() => _spinning = true);
    _wheel.forward(from: 0);
    final result = game.spinLuckyWheel();
    await Future.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;
    setState(() => _spinning = false);
    if (result != null) _popup(context, 'Lucky Wheel!', result);
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy2.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );

  void _popup(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navy2,
        title: Text('🎁 $title'),
        content: Text(body, style: const TextStyle(fontSize: 18)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nice!'))],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameState>();
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.navy,
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () => game.setWeather(value),
    );
  }
}
