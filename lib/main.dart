import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/save_service.dart';
import 'services/game_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/root_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RahinoApp());
}

class RahinoApp extends StatelessWidget {
  const RahinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(SaveService())..init(),
      child: MaterialApp(
        title: 'Rahino: Istanbul Treasure Hunt',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const RootScreen(),
      ),
    );
  }
}
