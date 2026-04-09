import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/arcade_stats_service.dart';
import '../services/game_haptics.dart';
import '../services/game_help.dart';
import '../services/haptic_arcade_button.dart';
import '../widgets/game_pause_overlay.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

const int rowCount = 20;
const int colCount = 20;
const Duration tickDuration = Duration(milliseconds: 200);

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  List<Point<int>> snake = [const Point(10, 10)];
  Direction direction = Direction.right;
  Point<int> food = const Point(5, 5);
  Timer? timer;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  bool isStarted = false;
  bool isPaused = false;
  Direction? nextDirection;

  AnimationController? _floatController;

  @override
  void initState() {
    super.initState();
    GameHaptics.preload();
    _loadHighScore();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('snake_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snake_high_score', highScore);
  }

  void _startGame() {
    ArcadeStatsService.recordPlay('snake');
    final initialSnake = [const Point(10, 10)];
    setState(() {
      snake = initialSnake;
      direction = Direction.right;
      nextDirection = null;
      food = _randomFood(initialSnake);
      isGameOver = false;
      score = 0;
      isStarted = true;
      isPaused = false;
    });
    timer?.cancel();
    timer = Timer.periodic(tickDuration, (_) => _tick());
  }

  void _endGame() {
    ArcadeStatsService.recordResult('snake', score: score, won: false);
    setState(() {
      isGameOver = true;
      isStarted = false;
    });
    timer?.cancel();
    GameHaptics.heavy();
    if (score > highScore) {
      setState(() {
        highScore = score;
      });
      _saveHighScore();
    }
  }

  Point<int> _randomFood([List<Point<int>>? occupied]) {
    final rand = Random();
    final blocked = occupied ?? snake;
    Point<int> p;
    do {
      p = Point(rand.nextInt(colCount), rand.nextInt(rowCount));
    } while (blocked.contains(p));
    return p;
  }

  void _tick() {
    if (!isStarted || isGameOver || isPaused) return;

    final pendingDirection = nextDirection;
    final nextDir =
        pendingDirection != null && !_isOpposite(pendingDirection, direction)
            ? pendingDirection
            : direction;
    final head = snake.first;
    late final Point<int> newHead;
    switch (nextDir) {
      case Direction.up:
        newHead = Point(head.x, (head.y - 1 + rowCount) % rowCount);
        break;
      case Direction.down:
        newHead = Point(head.x, (head.y + 1) % rowCount);
        break;
      case Direction.left:
        newHead = Point((head.x - 1 + colCount) % colCount, head.y);
        break;
      case Direction.right:
        newHead = Point((head.x + 1) % colCount, head.y);
        break;
    }

    final growing = newHead == food;
    if (_isCollision(newHead, growing)) {
      _endGame();
      return;
    }

    final updatedSnake = [newHead, ...snake];
    Point<int>? nextFoodPosition;
    if (growing) {
      nextFoodPosition = _randomFood(updatedSnake);
    } else {
      updatedSnake.removeLast();
    }

    setState(() {
      direction = nextDir;
      nextDirection = null;
      snake = updatedSnake;
      if (growing) {
        score++;
        food = nextFoodPosition!;
      }
    });
    if (growing) {
      GameHaptics.medium();
    }
  }

  bool _isCollision(Point<int> p, bool growing) {
    // Only check for self-collision
    final body = growing ? snake : snake.sublist(0, snake.length - 1);
    if (body.contains(p)) return true;
    return false;
  }

  bool _isOpposite(Direction a, Direction b) {
    return (a == Direction.up && b == Direction.down) ||
        (a == Direction.down && b == Direction.up) ||
        (a == Direction.left && b == Direction.right) ||
        (a == Direction.right && b == Direction.left);
  }

  Offset _dragDelta = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    _dragDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (isGameOver || !isStarted || isPaused) return;
    _dragDelta += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    if (isGameOver || !isStarted || isPaused) return;
    if (_dragDelta.distance < 10) return;

    Direction? newDir;
    if (_dragDelta.dx.abs() > _dragDelta.dy.abs()) {
      newDir = _dragDelta.dx > 0 ? Direction.right : Direction.left;
    } else {
      newDir = _dragDelta.dy > 0 ? Direction.down : Direction.up;
    }

    if (!_isOpposite(newDir, direction)) {
      nextDirection = newDir;
    }
    _dragDelta = Offset.zero;
    GameHaptics.tap();
  }

  void _togglePause() {
    if (!isStarted || isGameOver) return;
    setState(() {
      isPaused = !isPaused;
    });
    GameHaptics.light();
  }

  void _resume() {
    setState(() {
      isPaused = false;
    });
    GameHaptics.light();
  }

  @override
  void dispose() {
    timer?.cancel();
    _floatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF39FF14);
    final neonPink = const Color(0xFFFF00FF);
    final neonBlue = const Color(0xFF00FFF7);
    final neonRed = const Color(0xFFFF073A);
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Snake',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFF39FF14),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const GameHelpAction(
            title: 'Snake',
            accent: Color(0xFF39FF14),
            steps: [
              'Swipe or use the arrows to guide the snake.',
              'Eat stars to grow longer and raise your score.',
              'Do not crash into your own body.',
            ],
            tip: 'Plan two turns ahead once the snake gets long.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                'High: $highScore',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Orbitron',
                  color: Color(0xFFFF00FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 8)],
                ),
              ),
            ),
          ),
          if (isStarted && !isGameOver)
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              color: neonGreen,
              onPressed: _togglePause,
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: neonGreen.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Orbitron',
                        color: Color(0xFF39FF14),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size =
                            constraints.maxWidth < constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight;
                        return GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: _buildGrid(
                              neonGreen,
                              neonPink,
                              neonBlue,
                              neonRed,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Directional buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _directionButton(
                            Icons.arrow_upward,
                            Direction.up,
                            neonGreen,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _directionButton(
                            Icons.arrow_back,
                            Direction.left,
                            neonGreen,
                          ),
                          const SizedBox(width: 32),
                          _directionButton(
                            Icons.arrow_forward,
                            Direction.right,
                            neonGreen,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _directionButton(
                            Icons.arrow_downward,
                            Direction.down,
                            neonGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isGameOver)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Game Over',
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Orbitron',
                        color: neonRed,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: neonRed.withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _neonButton(
                    isGameOver || !isStarted ? 'Start Game' : 'Restart',
                    _startGame,
                    neonGreen,
                  ),
                ),
              ],
            ),
          ),
          if (isPaused)
            GamePauseOverlay(
              onResume: _resume,
              onRestart: _startGame,
              onQuit: () => Navigator.of(context).pop(),
              accentColor: neonGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    Color neonGreen,
    Color neonPink,
    Color neonBlue,
    Color neonRed,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / colCount;
        final cellHeight = constraints.maxHeight / rowCount;
        return Table(
          defaultColumnWidth: FixedColumnWidth(cellWidth),
          children: List.generate(rowCount, (y) {
            return TableRow(
              children: List.generate(colCount, (x) {
                final point = Point(x, y);
                if (snake.isNotEmpty && point == snake.first) {
                  // Snake head
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: neonBlue,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  );
                } else if (snake.contains(point)) {
                  // Snake body
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: neonPink,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  );
                } else if (point == food) {
                  // Food
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: neonGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: cellWidth * 0.6,
                    ),
                  );
                } else {
                  // Empty cell
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }
              }),
            );
          }),
        );
      },
    );
  }

  Widget _neonButton(String text, VoidCallback onPressed, Color color) {
    return ArcadeButton(label: text, color: color, onPressed: onPressed);
  }
  }

  Widget _directionButton(IconData icon, Direction dir, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ArcadeIconButton(
        icon: icon,
        color: color,
        size: 74,
        iconSize: 34,
        onPressed: () {
          if (!_isOpposite(dir, direction) &&
              isStarted &&
              !isGameOver &&
              !isPaused) {
            setState(() {
              nextDirection = dir;
            });
          }
        },
      ),
    );
  }
}
