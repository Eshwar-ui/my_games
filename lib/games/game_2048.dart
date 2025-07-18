import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  State<Game2048> createState() => _Game2048State();
}

const int gridSize = 4;

class _Game2048State extends State<Game2048> {
  List<List<int>>? board;
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isGameWon = false;
  bool isMoving = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startGame();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('2048_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('2048_high_score', highScore);
  }

  void _startGame() {
    setState(() {
      board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
      score = 0;
      isGameOver = false;
      isGameWon = false;
      isMoving = false;
    });
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    final empty = <Point<int>>[];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board![y][x] == 0) empty.add(Point(x, y));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[Random().nextInt(empty.length)];
    board![p.y][p.x] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  void _move(Direction dir) async {
    if (isMoving || isGameOver || isGameWon) return;
    setState(() => isMoving = true);
    final oldBoard = board!.map((row) => [...row]).toList();
    int gained = 0;
    List<List<bool>> merged = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      List<int> line = _getLine(i, dir);
      List<int> mergedLine = List.filled(gridSize, 0);
      int last = -1;
      int pos = 0;
      for (int j = 0; j < gridSize; j++) {
        if (line[j] == 0) continue;
        if (last != -1 && line[j] == mergedLine[last] && !merged[i][last]) {
          mergedLine[last] *= 2;
          gained += mergedLine[last];
          merged[i][last] = true;
          if (mergedLine[last] == 2048) isGameWon = true;
        } else {
          last = pos;
          mergedLine[pos++] = line[j];
        }
      }
      _setLine(i, dir, mergedLine);
    }
    if (!_boardsEqual(oldBoard, board!)) {
      moved = true;
      setState(() {
        score += gained;
        if (score > highScore) {
          highScore = score;
          _saveHighScore();
        }
      });
      await Future.delayed(const Duration(milliseconds: 120));
      setState(() {
        _addRandomTile();
        isGameOver = _isGameOver();
      });
    }
    setState(() => isMoving = false);
  }

  List<int> _getLine(int i, Direction dir) {
    switch (dir) {
      case Direction.left:
        return board![i];
      case Direction.right:
        return board![i].reversed.toList();
      case Direction.up:
        return [for (int j = 0; j < gridSize; j++) board![j][i]];
      case Direction.down:
        return [for (int j = gridSize - 1; j >= 0; j--) board![j][i]];
    }
  }

  void _setLine(int i, Direction dir, List<int> line) {
    switch (dir) {
      case Direction.left:
        board![i] = line;
        break;
      case Direction.right:
        board![i] = line.reversed.toList();
        break;
      case Direction.up:
        for (int j = 0; j < gridSize; j++) board![j][i] = line[j];
        break;
      case Direction.down:
        for (int j = gridSize - 1, k = 0; j >= 0; j--, k++)
          board![j][i] = line[k];
        break;
    }
  }

  bool _boardsEqual(List<List<int>> a, List<List<int>> b) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (a[y][x] != b[y][x]) return false;
      }
    }
    return true;
  }

  bool _isGameOver() {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board![y][x] == 0) return false;
        if (x < gridSize - 1 && board![y][x] == board![y][x + 1]) return false;
        if (y < gridSize - 1 && board![y][x] == board![y + 1][x]) return false;
      }
    }
    return true;
  }

  Offset? _dragStart;

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset dragEnd = box.globalToLocal(details.velocity.pixelsPerSecond);
    final Offset delta = dragEnd - _dragStart!;
    _dragStart = null;
    if (delta.distance < 40) return; // Minimum swipe distance
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 0) {
        _move(Direction.right);
      } else {
        _move(Direction.left);
      }
    } else {
      if (delta.dy > 0) {
        _move(Direction.down);
      } else {
        _move(Direction.up);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final neonYellow = const Color(0xFFFFFF00);
    final neonGreen = const Color(0xFF39FF14);
    final neonPink = const Color(0xFFFF00FF);
    final neonBlue = const Color(0xFF00FFF7);
    final neonOrange = const Color(0xFFFFA500);
    final neonRed = const Color(0xFFFF073A);
    final neonTileColors = [
      neonBlue,
      neonGreen,
      neonPink,
      neonYellow,
      neonOrange,
      neonRed,
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '2048',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFFFF00FF),
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
                  color: Color(0xFF39FF14),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Color(0xFF39FF14), blurRadius: 8)],
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
                    color: Color(0xFFFF00FF),
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
                      onPanEnd: _onPanEnd,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: neonPink, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: neonPink.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _buildGrid(neonTileColors),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (isGameOver || isGameWon)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isGameWon ? 'You Win!' : 'Game Over',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Orbitron',
                    color: isGameWon ? neonGreen : neonRed,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: (isGameWon ? neonGreen : neonRed).withOpacity(
                          0.5,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _neonButton('Restart', _startGame, neonPink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Color> neonTileColors) {
    if (board == null) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, index) {
        int x = index % gridSize;
        int y = index ~/ gridSize;
        int value = board![y][x];
        return _neonTile(value, neonTileColors);
      },
    );
  }

  Widget _neonTile(int value, List<Color> neonTileColors) {
    if (value == 0) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    int colorIndex = (value == 2)
        ? 0
        : (value == 4)
        ? 1
        : (value == 8)
        ? 2
        : (value == 16)
        ? 3
        : (value == 32)
        ? 4
        : 5;
    final color = neonTileColors[colorIndex];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 32,
            fontFamily: 'Orbitron',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: color.withOpacity(0.7), blurRadius: 8)],
          ),
        ),
      ),
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
}

enum Direction { up, down, left, right }
