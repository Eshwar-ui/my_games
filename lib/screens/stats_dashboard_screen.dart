import 'package:flutter/material.dart';

import '../services/arcade_stats_service.dart';

class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Stats Dashboard',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFF00FFF7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, ArcadeGameStats>>(
        future: ArcadeStatsService.loadAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          final totalPlays = stats.values.fold<int>(
            0,
            (sum, entry) => sum + entry.playCount,
          );
          final totalWins = stats.values.fold<int>(
            0,
            (sum, entry) => sum + entry.winCount,
          );
          final bestStreak = stats.values.fold<int>(
            0,
            (best, entry) => entry.bestStreak > best ? entry.bestStreak : best,
          );
          final topScore = stats.values.fold<int>(
            0,
            (best, entry) => entry.bestScore > best ? entry.bestScore : best,
          );
          final achievements = _buildAchievements(
            totalPlays: totalPlays,
            totalWins: totalWins,
            gamesPlayed: stats.entries
                .where((entry) => entry.value.playCount > 0)
                .length,
            bestStreak: bestStreak,
            topScore: topScore,
          );

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      label: 'Total Plays',
                      value: '$totalPlays',
                      color: const Color(0xFF00FFF7),
                    ),
                    _SummaryCard(
                      label: 'Wins',
                      value: '$totalWins',
                      color: const Color(0xFFFF00FF),
                    ),
                    _SummaryCard(
                      label: 'Best Streak',
                      value: '$bestStreak',
                      color: const Color(0xFF39FF14),
                    ),
                    _SummaryCard(
                      label: 'Top Score',
                      value: '$topScore',
                      color: const Color(0xFFFFC857),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFF7),
                  ),
                ),
                const SizedBox(height: 12),
                ...achievements.map(
                  (achievement) => _AchievementTile(
                    title: achievement.title,
                    subtitle: achievement.subtitle,
                    unlocked: achievement.unlocked,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Per Game',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF00FF),
                  ),
                ),
                const SizedBox(height: 12),
                ..._gameCatalog.entries.map((entry) {
                  final itemStats =
                      stats[entry.key] ?? const ArcadeGameStats.empty();
                  return _GameStatsTile(
                    title: entry.value.title,
                    color: entry.value.color,
                    stats: itemStats,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF201533),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.45), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? const Color(0xFF39FF14) : Colors.white24;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151022),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: unlocked ? color : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameStatsTile extends StatelessWidget {
  const _GameStatsTile({
    required this.title,
    required this.color,
    required this.stats,
  });

  final String title;
  final Color color;
  final ArcadeGameStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151022),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip('Plays ${stats.playCount}'),
              _statChip('Wins ${stats.winCount}'),
              _statChip('Losses ${stats.lossCount}'),
              _statChip('Best ${stats.bestScore}'),
              _statChip('Streak ${stats.bestStreak}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _Achievement {
  const _Achievement(this.title, this.subtitle, this.unlocked);

  final String title;
  final String subtitle;
  final bool unlocked;
}

class _GameMeta {
  const _GameMeta(this.title, this.color);

  final String title;
  final Color color;
}

List<_Achievement> _buildAchievements({
  required int totalPlays,
  required int totalWins,
  required int gamesPlayed,
  required int bestStreak,
  required int topScore,
}) {
  return [
    _Achievement('Arcade Boot', 'Play any game once.', totalPlays >= 1),
    _Achievement(
      'Explorer',
      'Try at least 4 different games.',
      gamesPlayed >= 4,
    ),
    _Achievement(
      'Winner\'s Circle',
      'Record 5 wins across the app.',
      totalWins >= 5,
    ),
    _Achievement(
      'Streak Keeper',
      'Reach a 3-game win streak.',
      bestStreak >= 3,
    ),
    _Achievement('Score Hunter', 'Post a score of 50 or more.', topScore >= 50),
  ];
}

const Map<String, _GameMeta> _gameCatalog = {
  'tic_tac_toe': _GameMeta('Tic-Tac-Toe', Color(0xFF00FFF7)),
  'brick_breaker': _GameMeta('Brick Breaker', Color(0xFFFFA500)),
  'tetris': _GameMeta('Tetris', Color(0xFFFF00FF)),
  'snake': _GameMeta('Snake', Color(0xFF39FF14)),
  'game_2048': _GameMeta('2048', Color(0xFFFFC857)),
  'flappy_bird': _GameMeta('Flappy Bird', Color(0xFFFFFF00)),
  'space_war': _GameMeta('Space War', Color(0xFF00FFF7)),
  'memory_match': _GameMeta('Memory Match', Color(0xFFFF6B6B)),
};
