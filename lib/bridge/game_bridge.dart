import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/game_state.dart';

/// Translates between the embedded 3D engine and [GameState].
///
///  * Outbound  : [send] -> window.RahinoEngine.cmd(name, data)
///  * Inbound   : [onEvent] handles the 'onGameEvent' JS handler payloads
///
/// Frequent live values (position, clock, weather, interact prompt) are exposed
/// as [ValueNotifier]s so only the relevant HUD widgets rebuild.
class GameBridge {
  GameBridge(this.game) {
    game.engineSend = send;
  }

  final GameState game;
  InAppWebViewController? controller;

  final ready = ValueNotifier<bool>(false);
  final position = ValueNotifier<Offset>(Offset.zero); // (x, z)
  final heading = ValueNotifier<double>(0);
  final hour = ValueNotifier<double>(8);
  final weather = ValueNotifier<String>('sunny');
  final interactLabel = ValueNotifier<String?>(null);
  final waypointDist = ValueNotifier<int?>(null);
  final rahinoSpeech = ValueNotifier<String?>(null);

  // UI callbacks
  void Function(String kind, String line)? onNpcDialogue;
  void Function(String panel)? onRequestPanel;
  void Function(String message)? onEngineError;

  void attach(InAppWebViewController c) {
    controller = c;
    c.addJavaScriptHandler(
      handlerName: 'onGameEvent',
      callback: (args) {
        if (args.isNotEmpty && args.first is Map) {
          onEvent(Map<String, dynamic>.from(args.first as Map));
        }
        return null;
      },
    );
  }

  void send(String name, Map<String, dynamic> data) {
    final js = "window.RahinoEngine && window.RahinoEngine.cmd("
        "${jsonEncode(name)}, ${jsonEncode(data)});";
    controller?.evaluateJavascript(source: js);
  }

  void onEvent(Map<String, dynamic> payload) {
    final event = payload['event'] as String?;
    final data = (payload['data'] is Map)
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : <String, dynamic>{};
    switch (event) {
      case 'ready':
        ready.value = true;
        break;
      case 'position':
        position.value = Offset(_d(data['x']), _d(data['z']));
        heading.value = _d(data['heading']);
        hour.value = _d(data['hour']);
        waypointDist.value = data['waypointDist'] == null ? null : (data['waypointDist'] as num).toInt();
        game.onPosition(position.value.dx, position.value.dy);
        break;
      case 'coinCollected':
        game.onCoinCollected();
        break;
      case 'chestOpened':
        game.onChestOpened();
        break;
      case 'landmarkDiscovered':
        game.onLandmarkDiscovered(data['id'] as String);
        break;
      case 'waypointReached':
        game.onWaypointReached(data['id'] as String);
        break;
      case 'photoTaken':
        game.onPhotoTaken(data['id'] as String);
        break;
      case 'npcInteract':
        final line = game.onNpcInteract(data['id'] as String, data['kind'] as String);
        onNpcDialogue?.call(data['kind'] as String, line);
        break;
      case 'interactable':
        interactLabel.value = data['label'] as String?;
        break;
      case 'weatherChanged':
        weather.value = data['weather'] as String? ?? 'sunny';
        break;
      case 'rahinoSpeak':
        rahinoSpeech.value = data['text'] as String?;
        break;
      case 'requestPanel':
        onRequestPanel?.call(data['panel'] as String);
        break;
      case 'error':
        onEngineError?.call(data['message'] as String? ?? 'Unknown engine error');
        break;
    }
  }

  double _d(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

  /// Detaches the engine sink. Notifiers are intentionally left for GC rather
  /// than disposed here, since HUD [ValueListenableBuilder]s may still be
  /// tearing down in the same frame.
  void dispose() {
    controller = null;
    game.engineSend = null;
  }
}
