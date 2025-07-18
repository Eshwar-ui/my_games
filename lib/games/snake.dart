import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

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
  Direction? nextDirection;

  AnimationController? _floatController;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      snake = [const Point(10, 10)];
      direction = Direction.right;
      nextDirection = null;
      food = _randomFood();
      isGameOver = false;
      score = 0;
      isStarted = true;
    });
    timer?.cancel();
    timer = Timer.periodic(tickDuration, (_) => _tick());
  }

  void _endGame() {
    setState(() {
      isGameOver = true;
      isStarted = false;
    });
    timer?.cancel();
    if (score > highScore) {
      setState(() {
        highScore = score;
      });
      _saveHighScore();
    }
  }

  Point<int> _randomFood() {
    final rand = Random();
    Point<int> p;
    do {
      p = Point(rand.nextInt(colCount), rand.nextInt(rowCount));
    } while (snake.contains(p));
    return p;
  }

  void _tick() {
    setState(() {
      final newDir = nextDirection;
      if (newDir != null && !_isOpposite(newDir, direction)) {
        direction = newDir;
      }
      final head = snake.first;
      Point<int> newHead;
      switch (direction) {
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
      final bool growing = (newHead == food);
      if (_isCollision(newHead, growing)) {
        _endGame();
        return;
      }
      snake = [newHead, ...snake];
      if (growing) {
        score++;
        food = _randomFood();
      } else {
        snake.removeLast();
      }
    });
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

  Offset? _dragStart;
  Offset? _dragUpdate;

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragUpdate = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _dragUpdate = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart == null || _dragUpdate == null) return;
    final Offset delta = _dragUpdate! - _dragStart!;
    _dragStart = null;
    _dragUpdate = null;
    if (delta.distance < 40) return; // Minimum swipe distance
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 0) {
        nextDirection = Direction.right;
      } else {
        nextDirection = Direction.left;
      }
    } else {
      if (delta.dy > 0) {
        nextDirection = Direction.down;
      } else {
        nextDirection = Direction.up;
      }
    }
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Card(
              color: Colors.white.withOpacity(0.1),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
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
                    final size = constraints.maxWidth < constraints.maxHeight
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

  Widget _neonCell(
    Color color, {
    IconData? icon,
    bool isHead = false,
    bool isFood = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(isFood ? 0.7 : 0.3),
        borderRadius: BorderRadius.circular(isHead ? 8 : 4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: isHead ? 16 : 8,
            spreadRadius: isHead ? 2 : 1,
          ),
        ],
        border: Border.all(color: color, width: isHead ? 2 : 1),
      ),
      child: icon != null
          ? Center(
              child: Icon(icon, color: Colors.white, size: isHead ? 22 : 18),
            )
          : null,
    );
  }

  Widget _neonButton(String text, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 3),
            color: Colors.white.withOpacity(0.08),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Orbitron',
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _realisticHead(double w, double h, Color color, Direction dir) {
    // Head is a larger circle with neon glow and two eyes
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: w * 0.85,
              height: h * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.3)],
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
          // Eyes
          ..._buildEyes(w, h, dir),
        ],
      ),
    );
  }

  List<Widget> _buildEyes(double w, double h, Direction dir) {
    // Eyes are two small white dots, positioned based on direction
    double dx = 0, dy = 0;
    switch (dir) {
      case Direction.up:
        dx = 0;
        dy = -h * 0.18;
        break;
      case Direction.down:
        dx = 0;
        dy = h * 0.18;
        break;
      case Direction.left:
        dx = -w * 0.18;
        dy = 0;
        break;
      case Direction.right:
        dx = w * 0.18;
        dy = 0;
        break;
    }
    return [
      Positioned(
        left: w * 0.32 + dx,
        top: h * 0.32 + dy,
        child: Container(
          width: w * 0.13,
          height: h * 0.13,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 2),
            ],
          ),
        ),
      ),
      Positioned(
        left: w * 0.55 + dx,
        top: h * 0.32 + dy,
        child: Container(
          width: w * 0.13,
          height: h * 0.13,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 2),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _realisticBodySegment(
    double w,
    double h,
    Color color,
    Color headColor,
    int i,
    int total,
  ) {
    // Body segments are slightly smaller, with a gradient for depth
    final double size = 0.7 + 0.2 * (i / total); // tail is smaller
    return Center(
      child: Container(
        width: w * size,
        height: h * size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color.lerp(color, headColor, i / total)!.withOpacity(0.8),
              color.withOpacity(0.3),
            ],
            radius: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: color, width: 1),
        ),
      ),
    );
  }

  Widget _realisticFood(double w, double h, Color color) {
    // Food is a glowing star
    return Center(
      child: Container(
        width: w * 0.7,
        height: h * 0.7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.star, color: Colors.white, size: w * 0.5),
      ),
    );
  }

  Widget _directionButton(IconData icon, Direction dir, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            // Prevent reversing direction
            if (!_isOpposite(dir, direction) && isStarted && !isGameOver) {
              setState(() {
                nextDirection = dir;
              });
              _tick(); // Move the snake instantly
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
      ),
    );
  }
}
