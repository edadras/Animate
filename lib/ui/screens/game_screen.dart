import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../../bridge/game_bridge.dart';
import '../../models/achievement.dart';
import '../../models/mission.dart';
import '../../services/game_state.dart';
import '../../theme/app_theme.dart';
import '../panels/live_panel.dart';
import '../panels/map_panel.dart';
import '../panels/missions_panel.dart';
import '../panels/profile_panel.dart';
import '../panels/sheet.dart';
import '../panels/shop_panel.dart';
import '../widgets/joystick.dart';
import '../widgets/minimap.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameBridge _bridge;
  late final GameState _game;
  final List<_Toast> _toasts = [];
  String? _levelUpText;
  String? _engineError;
  _DialogueData? _dialogue;
  bool _runOn = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _game = context.read<GameState>();
    final game = _game;
    _bridge = GameBridge(game);
    game.onToast = (msg, {String icon = '✨'}) => _pushToast(msg, icon);
    game.onLevelUp = (lvl) => _showLevelUp('Level $lvl!');
    game.onAchievement = _showAchievement;
    game.onMissionComplete = (m) => _pushToast('Mission complete!', '✅');
    _bridge.onNpcDialogue = (kind, line) => setState(() => _dialogue = _DialogueData(kind, line));
    _bridge.onEngineError = (m) => setState(() => _engineError = m);
    _bridge.onRequestPanel = _openPanelByName;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _bridge.dispose();
    _game.onToast = null;
    _game.onLevelUp = null;
    _game.onAchievement = null;
    _game.onMissionComplete = null;
    _game.saveNow();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  void _pushToast(String msg, String icon) {
    final t = _Toast(msg, icon);
    setState(() => _toasts.add(t));
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toasts.remove(t));
    });
  }

  void _showLevelUp(String text) {
    setState(() => _levelUpText = text);
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _levelUpText = null);
    });
  }

  void _showAchievement(Achievement a) {
    _pushToast('Achievement: ${a.name} (+${a.rewardCoins}🪙)', a.icon);
  }

  void _openPanelByName(String name) {
    switch (name) {
      case 'missions': _open(const MissionsPanel()); break;
      case 'shop': _open(const ShopPanel()); break;
      case 'profile': _open(const ProfilePanel()); break;
      case 'map': _open(MapPanel(bridge: _bridge)); break;
      case 'live': _open(LivePanel(bridge: _bridge)); break;
    }
  }

  void _open(Widget panel) {
    _bridge.send('move', {'x': 0, 'y': 0});
    Sheet.show(context, panel);
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          // ---- 3D engine ----
          InAppWebView(
            initialFile: 'assets/web3d/index.html',
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: false,
              supportZoom: false,
              disableHorizontalScroll: true,
              disableVerticalScroll: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
            ),
            onWebViewCreated: _bridge.attach,
            onConsoleMessage: (c, msg) => debugPrint('[web3d] ${msg.message}'),
          ),

          // ---- HUD ----
          SafeArea(
            child: Stack(
              children: [
                _topLeftProfile(),
                _topRightStats(),
                _missionTracker(),
                Positioned(right: 12, top: 70, child: _minimap()),
                _sideButtons(),
                _controls(),
                _actionButtons,
                _interactPrompt(),
                _toastColumn(),
                if (_dialogue != null) _dialogueBox(),
                if (_levelUpText != null) _levelUpOverlay(),
                if (_engineError != null) _engineErrorBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- HUD pieces ----
  Widget _topLeftProfile() {
    return Positioned(
      left: 12, top: 8,
      child: Consumer<GameState>(
        builder: (_, game, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: AppTheme.glassCard(radius: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 18, backgroundColor: AppColors.ember, child: Text('🦏', style: TextStyle(fontSize: 18))),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Text(game.profile.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                      child: Text(game.profile.title, style: const TextStyle(color: AppColors.navy, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text('Lv ${game.level}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 90,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: game.xpFraction,
                          minHeight: 6,
                          color: AppColors.gold,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRightStats() {
    return Positioned(
      right: 150, top: 8,
      child: Row(
        children: [
          Consumer<GameState>(
            builder: (_, game, __) => _chip('🪙 ${game.coins}', AppColors.gold, AppColors.navy),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<double>(
            valueListenable: _bridge.hour,
            builder: (_, h, __) => ValueListenableBuilder<String>(
              valueListenable: _bridge.weather,
              builder: (_, w, __) => _chip('${h.floor().toString().padLeft(2, '0')}:00 ${_weatherIcon(w)}', AppColors.glassDark, Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
      );

  Widget _minimap() {
    return ValueListenableBuilder<Offset>(
      valueListenable: _bridge.position,
      builder: (_, pos, __) => ValueListenableBuilder<double>(
        valueListenable: _bridge.heading,
        builder: (_, head, __) {
          final game = context.read<GameState>();
          return Minimap(
            player: pos,
            heading: head,
            discovered: game.profile.discoveredLandmarks,
            waypointId: game.activeMission?.targetLandmarkId,
          );
        },
      ),
    );
  }

  Widget _missionTracker() {
    return Positioned(
      left: 12, top: 64,
      child: Consumer<GameState>(
        builder: (_, game, __) {
          final m = game.activeMission;
          return GestureDetector(
            onTap: () => _open(const MissionsPanel()),
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(10),
              decoration: AppTheme.glassCard(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(m?.icon ?? '🎯', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(m?.title ?? 'Tap to choose a mission',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ]),
                  if (m != null) ...[
                    const SizedBox(height: 4),
                    Text(m.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    if (m.targetCount > 1) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (game.activeProgress / m.targetCount).clamp(0.0, 1.0),
                          minHeight: 5, color: AppColors.teal, backgroundColor: Colors.white12,
                        ),
                      ),
                    ],
                    ValueListenableBuilder<int?>(
                      valueListenable: _bridge.waypointDist,
                      builder: (_, d, __) => d == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('📍 ${d}m to destination',
                                  style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sideButtons() {
    Widget btn(String icon, VoidCallback onTap, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color ?? AppColors.glassDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
            ),
          ),
        );
    return Positioned(
      right: 12, bottom: 12,
      child: Column(
        children: [
          if (context.select<GameState, bool>((g) => g.dailyRewardAvailable))
            btn('🎁', () => _open(LivePanel(bridge: _bridge)), color: AppColors.ember),
          if (!context.select<GameState, bool>((g) => g.dailyRewardAvailable))
            btn('🎁', () => _open(LivePanel(bridge: _bridge))),
          btn('📜', () => _open(const MissionsPanel())),
          btn('🛍️', () => _open(const ShopPanel())),
          btn('👤', () => _open(const ProfilePanel())),
          btn('🗺️', () => _open(MapPanel(bridge: _bridge))),
          btn('☰', () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }

  Widget _controls() {
    return Positioned(
      left: 16, bottom: 16,
      child: Joystick(onChanged: (v) {
        _bridge.send('move', {'x': v.dx, 'y': v.dy, 'run': _runOn});
      }),
    );
  }

  Widget _interactPrompt() {
    return Positioned(
      left: 0, right: 0, bottom: 170,
      child: Column(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _bridge.interactLabel,
            builder: (_, label, __) => label == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                    child: Text('✋ $label', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800)),
                  ),
          ),
        ],
      ),
    );
  }

  // Action buttons (interact / jump / run / photo)
  Widget get _actionButtons => Positioned(
        right: 70, bottom: 18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _actionBtn('✋', () => _bridge.send('interact', {})),
                const SizedBox(width: 10),
                _actionBtn('⤴︎', () => _bridge.send('jump', {})),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionBtn(_runOn ? '🏃' : '🚶', () {
                  setState(() => _runOn = !_runOn);
                  _bridge.send('run', {'on': _runOn});
                }, active: _runOn),
                const SizedBox(width: 10),
                if (context.select<GameState, bool>((g) => g.activeMission?.type == MissionType.photo))
                  _actionBtn('📷', () => _bridge.send('photo', {})),
              ],
            ),
          ],
        ),
      );

  Widget _actionBtn(String icon, VoidCallback onTap, {bool active = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: active ? AppColors.teal : AppColors.glassDark,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 2),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
        ),
      );

  Widget _toastColumn() {
    return Positioned(
      left: 0, right: 0, top: 130,
      child: Column(
        children: _toasts
            .map((t) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.glassDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                  ),
                  child: Text('${t.icon}  ${t.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ))
            .toList(),
      ),
    );
  }

  Widget _dialogueBox() {
    final d = _dialogue!;
    return Positioned(
      left: 24, right: 24, bottom: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.skyGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.speaker, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text(d.line, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => setState(() => _dialogue = null),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelUpOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black26,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 48)),
                    Text(_levelUpText ?? '',
                        style: const TextStyle(color: AppColors.navy, fontSize: 28, fontWeight: FontWeight.w900)),
                    const Text('Level Up!', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _engineErrorBanner() {
    return Positioned(
      left: 12, right: 12, bottom: 90,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '3D engine needs network for first load (Three.js). $_engineError',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            IconButton(onPressed: () => setState(() => _engineError = null), icon: const Icon(Icons.close, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _weatherIcon(String w) {
    switch (w) {
      case 'rain': return '🌧️';
      case 'fog': return '🌫️';
      case 'snow': return '❄️';
      case 'sunset': return '🌇';
      default: return '☀️';
    }
  }
}

class _Toast {
  _Toast(this.text, this.icon);
  final String text;
  final String icon;
}

class _DialogueData {
  _DialogueData(this.speaker, this.line);
  final String speaker;
  final String line;
}
