import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Consistent draggable bottom-sheet scaffold used by every panel.
class Sheet extends StatelessWidget {
  const Sheet({super.key, required this.title, required this.icon, required this.child});

  final String title;
  final String icon;
  final Widget child;

  static Future<T?> show<T>(BuildContext context, Widget panel) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.skyGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.gold, width: 2)),
          ),
          child: PrimaryScrollController(controller: controller, child: panel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(3))),
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
