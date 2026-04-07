import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ArcadeGameStats {
  const ArcadeGameStats({
    required this.playCount,
    required this.winCount,
    required this.lossCount,
    required this.bestScore,
    required this.currentStreak,
    required this.bestStreak,
  });

  const ArcadeGameStats.empty()
      : playCount = 0,
        winCount = 0,
        lossCount = 0,
        bestScore = 0,
        currentStreak = 0,
        bestStreak = 0;

  final int playCount;
  final int winCount;
  final int lossCount;
  final int bestScore;
  final int currentStreak;
  final int bestStreak;

  ArcadeGameStats copyWith({
    int? playCount,
    int? winCount,
    int? lossCount,
    int? bestScore,
    int? currentStreak,
    int? bestStreak,
  }) {
    return ArcadeGameStats(
      playCount: playCount ?? this.playCount,
      winCount: winCount ?? this.winCount,
      lossCount: lossCount ?? this.lossCount,
      bestScore: bestScore ?? this.bestScore,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playCount': playCount,
      'winCount': winCount,
      'lossCount': lossCount,
      'bestScore': bestScore,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  factory ArcadeGameStats.fromJson(Map<String, dynamic> json) {
    return ArcadeGameStats(
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      winCount: (json['winCount'] as num?)?.toInt() ?? 0,
      lossCount: (json['lossCount'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArcadeStatsService {
  static const String _statsKey = 'arcade_stats_v1';

  static Future<Map<String, ArcadeGameStats>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        ArcadeGameStats.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  static Future<void> recordPlay(String gameId) async {
    final stats = await loadAll();
    final current = stats[gameId] ?? const ArcadeGameStats.empty();
    stats[gameId] = current.copyWith(playCount: current.playCount + 1);
    await _saveAll(stats);
  }

  static Future<void> recordResult(
    String gameId, {
    int score = 0,
    bool won = false,
  }) async {
    final stats = await loadAll();
    final current = stats[gameId] ?? const ArcadeGameStats.empty();
    final nextCurrentStreak = won ? current.currentStreak + 1 : 0;
    stats[gameId] = current.copyWith(
      winCount: current.winCount + (won ? 1 : 0),
      lossCount: current.lossCount + (won ? 0 : 1),
      bestScore: score > current.bestScore ? score : current.bestScore,
      currentStreak: nextCurrentStreak,
      bestStreak: nextCurrentStreak > current.bestStreak
          ? nextCurrentStreak
          : current.bestStreak,
    );
    await _saveAll(stats);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }

  static Future<void> _saveAll(Map<String, ArcadeGameStats> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = stats.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_statsKey, jsonEncode(payload));
  }
}
