import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// On-screen virtual joystick. Reports a normalised vector where up is
/// negative-y (matching the engine's forward convention).
class Joystick extends StatefulWidget {
  const Joystick({super.key, required this.onChanged, this.size = 130});

  final ValueChanged<Offset> onChanged;
  final double size;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _knob = Offset.zero;

  void _update(Offset local) {
    final c = widget.size / 2;
    var v = local - Offset(c, c);
    final maxR = c - 18;
    if (v.distance > maxR) v = v / v.distance * maxR;
    setState(() => _knob = v);
    widget.onChanged(Offset(v.dx / maxR, v.dy / maxR));
  }

  void _end() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.28),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: _knob,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                ),
                child: const Icon(Icons.open_with, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
