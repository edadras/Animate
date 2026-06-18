import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/leaderboard_entry.dart';

/// Cloud sync client for saves + the global leaderboard.
///
/// Every call is best-effort and never throws to the caller — if the backend is
/// unset or unreachable the game just keeps using local data (offline-first).
/// Enable by setting [kCloudBaseUrl] (see lib/config.dart).
class CloudService {
  static const _idKey = 'rahino_player_id';
  String? _playerId;

  bool get enabled => kCloudBaseUrl.isNotEmpty;

  Future<String> playerId() async {
    if (_playerId != null) return _playerId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey);
    if (id == null) {
      id = 'p_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond * 7919) % 100000}';
      await prefs.setString(_idKey, id);
    }
    _playerId = id;
    return id;
  }

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$kCloudBaseUrl$path').replace(queryParameters: q);

  Future<void> uploadSave(Map<String, dynamic> profile) async {
    if (!enabled) return;
    try {
      final id = await playerId();
      await http
          .post(_u('/save'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'playerId': id, 'profile': profile}))
          .timeout(const Duration(seconds: 6));
    } catch (_) {/* offline — ignore */}
  }

  Future<Map<String, dynamic>?> downloadSave() async {
    if (!enabled) return null;
    try {
      final id = await playerId();
      final res = await http.get(_u('/save', {'playerId': id})).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['profile'] is Map) {
          return Map<String, dynamic>.from(body['profile'] as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> submitScore({required String name, required int score, required int level}) async {
    if (!enabled) return;
    try {
      final id = await playerId();
      await http
          .post(_u('/score'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'playerId': id, 'name': name, 'score': score, 'level': level}))
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 20}) async {
    if (!enabled) return [];
    try {
      final id = await playerId();
      final res = await http
          .get(_u('/leaderboard', {'limit': '$limit'}))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) => LeaderboardEntry.fromJson(
                    Map<String, dynamic>.from(e),
                    isMe: e['playerId'] == id,
                  ))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
