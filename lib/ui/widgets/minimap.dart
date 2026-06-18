import 'package:flutter/material.dart';
import '../../data/world_coords.dart';
import '../../data/landmarks_data.dart';
import '../../theme/app_theme.dart';

class Minimap extends StatelessWidget {
  const Minimap({
    super.key,
    required this.player,
    required this.heading,
    required this.discovered,
    this.waypointId,
  });

  final Offset player;
  final double heading;
  final Set<String> discovered;
  final String? waypointId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.glassDark,
        border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _MinimapPainter(
            player: player,
            heading: heading,
            discovered: discovered,
            waypointId: waypointId,
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.player,
    required this.heading,
    required this.discovered,
    required this.waypointId,
  });

  final Offset player;
  final double heading;
  final Set<String> discovered;
  final String? waypointId;

  static const double range = 220; // world units visible across the minimap

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bg = Paint()..color = const Color(0xFF14324a);
    canvas.drawRect(Offset.zero & size, bg);

    // water band hint
    final water = Paint()..color = const Color(0xFF1f5e8c).withOpacity(0.5);
    canvas.drawCircle(center, size.width / 2, water..style = PaintingStyle.stroke..strokeWidth = 2);

    Offset toMap(Offset world) {
      final dx = (world.dx - player.dx) / range * (size.width / 2);
      final dz = (world.dy - player.dy) / range * (size.height / 2);
      return center + Offset(dx, dz);
    }

    for (final lm in kLandmarks) {
      final w = kWorldCoords[lm.id];
      if (w == null) continue;
      final p = toMap(w);
      if ((p - center).distance > size.width / 2) continue;
      final isWp = lm.id == waypointId;
      final disc = discovered.contains(lm.id);
      final paint = Paint()
        ..color = isWp
            ? AppColors.gold
            : (disc ? AppColors.teal : Colors.white38);
      canvas.drawCircle(p, isWp ? 5 : 3, paint);
      if (isWp) {
        canvas.drawCircle(p, 8, Paint()..color = AppColors.gold.withOpacity(0.3));
      }
    }

    // player arrow
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading);
    final arrow = Path()
      ..moveTo(0, -7)
      ..lineTo(5, 6)
      ..lineTo(0, 3)
      ..lineTo(-5, 6)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white);
    canvas.drawPath(arrow, Paint()..color = AppColors.ember..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) =>
      old.player != player || old.heading != heading || old.waypointId != waypointId;
}
