import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

const int rowCount = 20;
const int colCount = 10;
const int blockSize = 20;

// Funky neon colors for blocks
const tetrominoColors = [
  Color(0xFF00FFF7), // Neon cyan
  Color(0xFFFFFF00), // Neon yellow
  Color(0xFFFF00FF), // Neon magenta
  Color(0xFF39FF14), // Neon green
  Color(0xFFFF073A), // Neon red
  Color(0xFF1E90FF), // Neon blue
  Color(0xFFFFA500), // Neon orange
];

const tetrominoShapes = [
  // I
  [
    [1, 1, 1, 1],
  ],
  // O
  [
    [1, 1],
    [1, 1],
  ],
  // T
  [
    [0, 1, 0],
    [1, 1, 1],
  ],
  // S
  [
    [0, 1, 1],
    [1, 1, 0],
  ],
  // Z
  [
    [1, 1, 0],
    [0, 1, 1],
  ],
  // J
  [
    [1, 0, 0],
    [1, 1, 1],
  ],
  // L
  [
    [0, 0, 1],
    [1, 1, 1],
  ],
];

class Tetromino {
  List<List<int>> shape;
  int row;
  int col;
  int type;
  Tetromino(this.shape, this.row, this.col, this.type);

  Tetromino copyWith({List<List<int>>? shape, int? row, int? col, int? type}) {
    return Tetromino(
      shape ?? this.shape,
      row ?? this.row,
      col ?? this.col,
      type ?? this.type,
    );
  }

  void rotate() {
    final n = shape.length;
    final m = shape[0].length;
    List<List<int>> rotated = List.generate(m, (_) => List.filled(n, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        rotated[j][n - i - 1] = shape[i][j];
      }
    }
    shape = rotated;
  }
}

class _TetrisGameState extends State<TetrisGame> {
  List<List<int?>> grid = List.generate(
    rowCount,
    (_) => List.filled(colCount, null),
  );
  Tetromino? current;
  Tetromino? next;
  Timer? timer;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  bool isStarted = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    // Do not start the game immediately
    isStarted = false;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('tetris_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tetris_high_score', highScore);
  }

  void _startGame() {
    setState(() {
      grid = List.generate(rowCount, (_) => List.filled(colCount, null));
      isGameOver = false;
      score = 0;
      isStarted = true;
      _spawnTetromino();
      next = _randomTetromino();
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _tick());
  }

  Tetromino _randomTetromino() {
    final type = Random().nextInt(tetrominoShapes.length);
    final shape = tetrominoShapes[type]
        .map((row) => List<int>.from(row))
        .toList();
    return Tetromino(shape, 0, (colCount ~/ 2) - (shape[0].length ~/ 2), type);
  }

  void _spawnTetromino() {
    current = next ?? _randomTetromino();
    next = _randomTetromino();
    if (_collides(current!)) {
      isGameOver = true;
      timer?.cancel();
      if (score > highScore) {
        setState(() {
          highScore = score;
        });
        _saveHighScore();
      }
    }
  }

  bool _collides(Tetromino t) {
    for (int i = 0; i < t.shape.length; i++) {
      for (int j = 0; j < t.shape[i].length; j++) {
        if (t.shape[i][j] == 0) continue;
        int r = t.row + i;
        int c = t.col + j;
        if (r < 0 || r >= rowCount || c < 0 || c >= colCount) return true;
        if (grid[r][c] != null) return true;
      }
    }
    return false;
  }

  void _fixTetromino() {
    if (current == null) return;
    for (int i = 0; i < current!.shape.length; i++) {
      for (int j = 0; j < current!.shape[i].length; j++) {
        if (current!.shape[i][j] == 0) continue;
        int r = current!.row + i;
        int c = current!.col + j;
        if (r >= 0 && r < rowCount && c >= 0 && c < colCount) {
          grid[r][c] = current!.type;
        }
      }
    }
    _clearLines();
    _spawnTetromino();
  }

  void _clearLines() {
    int lines = 0;
    grid.removeWhere((row) {
      if (row.every((cell) => cell != null)) {
        lines++;
        return true;
      }
      return false;
    });
    while (grid.length < rowCount) {
      grid.insert(0, List.filled(colCount, null));
    }
    if (lines > 0) {
      score += lines * 100;
      if (score > highScore) {
        setState(() {
          highScore = score;
        });
        _saveHighScore();
      }
    }
  }

  void _tick() {
    if (isGameOver || current == null) return;
    final moved = current!.copyWith(row: current!.row + 1);
    if (_collides(moved)) {
      _fixTetromino();
    } else {
      setState(() {
        current = moved;
      });
    }
  }

  void _move(int dx) {
    if (isGameOver || current == null) return;
    final moved = current!.copyWith(col: current!.col + dx);
    if (!_collides(moved)) {
      setState(() {
        current = moved;
      });
    }
  }

  void _rotate() {
    if (isGameOver || current == null) return;
    final rotated = current!.copyWith(
      shape: current!.shape.map((row) => List<int>.from(row)).toList(),
    );
    rotated.rotate();
    if (!_collides(rotated)) {
      setState(() {
        current = rotated;
      });
    }
  }

  void _drop() {
    if (isGameOver || current == null) return;
    Tetromino dropped = current!;
    while (!_collides(dropped.copyWith(row: dropped.row + 1))) {
      dropped = dropped.copyWith(row: dropped.row + 1);
    }
    setState(() {
      current = dropped;
    });
    _fixTetromino();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tetris',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFF00FFF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF39FF14)),
            onPressed: _startGame,
            tooltip: 'Restart',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxGridHeight = constraints.maxHeight * 0.6;
            if (!isStarted || isGameOver) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGameOver)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Game Over',
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'Orbitron',
                            color: Colors.redAccent.shade200,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    _neonStartButton(),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Card(
                  color: Colors.white.withOpacity(0.12),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'High Score: $highScore',
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Orbitron',
                        color: Color(0xFFFF00FF),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
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
                        color: Color(0xFF00FFF7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      // No border radius for sharp corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: const Color(0xFF00FFF7),
                          width: 2,
                        ),
                        backgroundBlendMode: BlendMode.overlay,
                        // No borderRadius
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxGridHeight,
                          maxWidth: constraints.maxWidth,
                        ),
                        child: AspectRatio(
                          aspectRatio: colCount / rowCount,
                          child: _buildGrid(),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _funkyButton(
                          Icons.arrow_left,
                          () => _move(-1),
                          const Color(0xFF1E90FF),
                          size: 80,
                          iconSize: 44,
                        ),
                        const SizedBox(width: 18),
                        _funkyButton(
                          Icons.rotate_right,
                          _rotate,
                          const Color(0xFFFF00FF),
                          size: 80,
                          iconSize: 44,
                        ),
                        const SizedBox(width: 18),
                        _funkyButton(
                          Icons.arrow_right,
                          () => _move(1),
                          const Color(0xFFFFA500),
                          size: 80,
                          iconSize: 44,
                        ),
                        const SizedBox(width: 18),
                        _funkyButton(
                          Icons.arrow_downward,
                          _drop,
                          const Color(0xFF39FF14),
                          size: 80,
                          iconSize: 44,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _neonStartButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _startGame,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00FFF7), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFF7).withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
            color: Colors.white.withOpacity(0.08),
          ),
          child: const Text(
            'START GAME',
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Orbitron',
              color: Color(0xFF00FFF7),
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _funkyButton(
    IconData icon,
    VoidCallback onPressed,
    Color color, {
    double size = 64,
    double iconSize = 36,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6), // Minimal rounded edges
      elevation: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    List<List<int?>> displayGrid = List.generate(
      rowCount,
      (r) => List<int?>.from(grid[r]),
    );
    if (current != null) {
      for (int i = 0; i < current!.shape.length; i++) {
        for (int j = 0; j < current!.shape[i].length; j++) {
          if (current!.shape[i][j] == 0) continue;
          int r = current!.row + i;
          int c = current!.col + j;
          if (r >= 0 && r < rowCount && c >= 0 && c < colCount) {
            displayGrid[r][c] = current!.type;
          }
        }
      }
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colCount,
      ),
      itemCount: rowCount * colCount,
      itemBuilder: (context, index) {
        int r = index ~/ colCount;
        int c = index % colCount;
        int? type = displayGrid[r][c];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: type == null
                ? Colors.white.withOpacity(0.05)
                : tetrominoColors[type],
            borderRadius: BorderRadius.circular(6),
            boxShadow: type == null
                ? []
                : [
                    BoxShadow(
                      color: tetrominoColors[type].withOpacity(0.7),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
            border: Border.all(
              color: type == null ? Colors.white12 : Colors.white,
              width: type == null ? 1 : 2,
            ),
          ),
        );
      },
    );
  }
}
