import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../bridge/game_bridge.dart';
import '../../data/landmarks_data.dart';
import '../../data/world_coords.dart';
import '../../models/landmark.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import 'sheet.dart';

class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.bridge});
  final GameBridge bridge;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Sheet(
      title: 'City Map',
      icon: '🗺️',
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E2336),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: ValueListenableBuilder<Offset>(
                valueListenable: bridge.position,
                builder: (_, pos, __) => CustomPaint(
                  painter: _MapPainter(player: pos, discovered: game.profile.discoveredLandmarks),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: kLandmarks.map((l) => _MapTile(landmark: l, bridge: bridge)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile({required this.landmark, required this.bridge});
  final Landmark landmark;
  final GameBridge bridge;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final discovered = game.profile.discoveredLandmarks.contains(landmark.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy2.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(landmark.icon, style: const TextStyle(fontSize: 26)),
        title: Text(landmark.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(discovered ? landmark.blurb : '??? — discover this place to learn more',
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: discovered
            ? const Icon(Icons.location_on, color: AppColors.teal)
            : const Icon(Icons.help_outline, color: Colors.white30),
        onTap: () => _options(context, game),
      ),
    );
  }

  void _options(BuildContext context, GameState game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy2,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${landmark.icon}  ${landmark.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            if (game.profile.discoveredLandmarks.contains(landmark.id))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('💡 ${landmark.funFact}',
                    style: const TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.flag, color: AppColors.gold),
              title: const Text('Set as waypoint'),
              onTap: () {
                bridge.send('setWaypoint', {'id': landmark.id});
                Navigator.pop(context);
                Navigator.of(context).maybePop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: AppColors.teal),
              title: const Text('Fast travel'),
              subtitle: const Text('Requires discovery or VIP Travel Pass'),
              onTap: () {
                game.fastTravel(landmark.id);
                Navigator.pop(context);
                Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.player, required this.discovered});
  final Offset player;
  final Set<String> discovered;

  @override
  void paint(Canvas canvas, Size size) {
    Offset toScreen(Offset w) => Offset(
          (w.dx / kWorldHalf * 0.5 + 0.5) * size.width,
          (w.dy / kWorldHalf * 0.5 + 0.5) * size.height,
        );

    // water band
    final water = Paint()..color = const Color(0xFF1f5e8c).withOpacity(0.45);
    final path = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width * 0.78, size.height)
      ..lineTo(size.width * 0.55, 0)
      ..close();
    canvas.drawPath(path, water);

    for (final l in kLandmarks) {
      final w = kWorldCoords[l.id];
      if (w == null) continue;
      final p = toScreen(w);
      final disc = discovered.contains(l.id);
      canvas.drawCircle(p, 5, Paint()..color = disc ? AppColors.teal : Colors.white30);
      if (disc) {
        final tp = TextPainter(
          text: TextSpan(text: l.icon, style: const TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height + 4));
      }
    }

    // player
    final pp = toScreen(player);
    canvas.drawCircle(pp, 7, Paint()..color = AppColors.ember);
    canvas.drawCircle(pp, 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.player != player;
}
