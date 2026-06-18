import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_state.dart';
import 'loading_screen.dart';
import 'main_menu_screen.dart';

/// Shows the loading screen until [GameState] finishes initialising, then the
/// main menu.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<GameState, bool>((g) => g.loaded);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: loaded ? const MainMenuScreen() : const LoadingScreen(),
    );
  }
}
