import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧭', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (r) => AppTheme.goldGradient.createShader(r),
                child: const Text('RAHINO',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
              ),
              const Text('Istanbul Treasure Hunt',
                  style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 1)),
              const SizedBox(height: 32),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  color: AppColors.gold,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Loading Istanbul…', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
