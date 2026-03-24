import 'package:flutter/material.dart';
// Add import for the TicTacToe game (to be created)
import 'games/tic_tac_toe.dart';
import 'games/brick_breaker.dart';
import 'games/tetris.dart';
import 'games/snake.dart';
import 'games/game_2048.dart';
import 'games/flappy_bird.dart';
import 'games/space_war.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF18122B),
        fontFamily: 'Orbitron',
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF00FFF7),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF00FFF7),
              secondary: const Color(0xFFFF00FF),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF00FFF7),
            letterSpacing: 2,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF00FFF7),
          textColor: Color(0xFF00FFF7),
        ),
      ),
      home: const GameSelectionScreen(),
    );
  }
}

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <_GameEntry>[
      _GameEntry(
        title: 'Tic-Tac-Toe',
        subtitle: 'Fast duels and clean strategy.',
        icon: Icons.grid_3x3,
        color: const Color(0xFF00FFF7),
        builder: (_) => const TicTacToeGame(),
      ),
      _GameEntry(
        title: 'Brick Breaker',
        subtitle: 'Arcade rebounds with neon walls.',
        icon: Icons.sports_tennis,
        color: const Color(0xFFFFA500),
        builder: (_) => const BrickBreakerGame(),
      ),
      _GameEntry(
        title: 'Tetris',
        subtitle: 'Stack fast and keep the board alive.',
        icon: Icons.view_column,
        color: const Color(0xFFFF00FF),
        builder: (_) => const TetrisGame(),
      ),
      _GameEntry(
        title: 'Snake',
        subtitle: 'Sharp turns, clean lines, no mistakes.',
        icon: Icons.show_chart,
        color: const Color(0xFF39FF14),
        builder: (_) => const SnakeGame(),
      ),
      _GameEntry(
        title: '2048',
        subtitle: 'Merge upward and chase bigger tiles.',
        icon: Icons.grid_4x4,
        color: const Color(0xFFFFC857),
        builder: (_) => const Game2048(),
      ),
      _GameEntry(
        title: 'Flappy Bird',
        subtitle: 'Thread the gaps and hold your rhythm.',
        icon: Icons.flight,
        color: const Color(0xFFFFFF00),
        builder: (_) => const FlappyBirdGame(),
      ),
      _GameEntry(
        title: 'Space War',
        subtitle: 'Sprite dogfights and wave pressure.',
        icon: Icons.rocket_launch,
        color: const Color(0xFF00FFF7),
        builder: (_) => const SpaceWarGame(),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF120B22), Color(0xFF18122B), Color(0xFF0F1A2C)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              //     child: _HomeHero(totalGames: games.length),
              //   ),
              // ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Center(
                    child: Text(
                      "RETRO GAMES",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00FFF7),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width >= 980
                        ? 3
                        : width >= 640
                        ? 2
                        : 1;
                    final cardHeight = columns == 1 ? 168.0 : 188.0;

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final game = games[index];
                        return _GameCard(
                          game: game,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: game.builder),
                            );
                          },
                        );
                      }, childCount: games.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        mainAxisExtent: cardHeight,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.totalGames});

  final int totalGames;

  @override
  Widget build(BuildContext context) {
    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x2200FFF7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF00FFF7).withOpacity(0.4)),
          ),
          child: const Text(
            'ARCADE HUB',
            style: TextStyle(
              color: Color(0xFF00FFF7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pick a Neon Run.',
          style: TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$totalGames playable modes. Bigger tap targets, cleaner layouts, and fast restarts.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.white.withOpacity(0.76),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2218FFF3), Color(0x22FF00FF), Color(0x22FFE66D)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(color: Color(0x2200FFF7), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroText,
                    const SizedBox(height: 18),
                    _HeroBadge(totalGames: totalGames, compact: true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heroText),
                    const SizedBox(width: 18),
                    _HeroBadge(totalGames: totalGames, compact: false),
                  ],
                );
        },
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.totalGames, required this.compact});

  final int totalGames;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 176,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2034).withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE66D).withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.videogame_asset_rounded,
            size: 34,
            color: Color(0xFFFFE66D),
          ),
          const SizedBox(height: 10),
          Text(
            '$totalGames',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFE66D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'games ready',
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final _GameEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF23173A),
                const Color(0xFF141A2C),
                game.color.withOpacity(0.16),
              ],
            ),
            border: Border.all(color: game.color.withOpacity(0.75), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: game.color.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: game.color.withOpacity(0.12),
                        border: Border.all(color: game.color.withOpacity(0.55)),
                      ),
                      child: Icon(game.icon, color: game.color, size: 28),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: game.color.withOpacity(0.9),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  game.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: game.color,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: game.color.withOpacity(0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.74),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}
