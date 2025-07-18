import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class BrickBreakerGame extends StatefulWidget {
  const BrickBreakerGame({super.key});

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame> {
  static const int rowCount = 5;
  static const int colCount = 7;
  static const double brickHeight = 20;
  static const double brickGap = 4;
  static const double paddleWidth = 80;
  static const double paddleHeight = 16;
  static const double ballRadius = 10;

  double paddleX = 0;
  double ballX = 0;
  double ballY = 0;
  double ballVX = 3;
  double ballVY = -3;
  List<List<bool>> bricks = [];
  bool isPlaying = false;
  bool isGameOver = false;
  bool isGameWon = false;
  Timer? gameTimer;
  Size? lastSize;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('brick_breaker_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brick_breaker_high_score', highScore);
  }

  void _initializeGameState(double width, double height) {
    paddleX = (width - paddleWidth) / 2;
    ballX = width / 2;
    ballY = height - 60;
    ballVX = 4;
    ballVY = -4;
    bricks = List.generate(rowCount, (_) => List.filled(colCount, true));
    isPlaying = true;
    isGameOver = false;
    isGameWon = false;
    gameTimer?.cancel();
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 12),
      (_) => _updateGame(width, height),
    );
  }

  int _calculateScore() {
    int total = 0;
    for (var row in bricks) {
      for (var b in row) {
        if (!b) total++;
      }
    }
    return total;
  }

  void _startGame(double width, double height) {
    setState(() {
      _initializeGameState(width, height);
    });
  }

  void _updateGame(double width, double height) {
    if (!isPlaying) return;
    setState(() {
      ballX += ballVX;
      ballY += ballVY;

      if (ballX - ballRadius < 0) {
        ballX = ballRadius;
        ballVX = -ballVX;
      } else if (ballX + ballRadius > width) {
        ballX = width - ballRadius;
        ballVX = -ballVX;
      }
      if (ballY - ballRadius < 0) {
        ballY = ballRadius;
        ballVY = -ballVY;
      }

      double paddleTop = height - paddleHeight - 20;
      if (ballY + ballRadius >= paddleTop &&
          ballY + ballRadius <= paddleTop + paddleHeight &&
          ballX >= paddleX &&
          ballX <= paddleX + paddleWidth) {
        ballY = paddleTop - ballRadius;
        ballVY = -ballVY;
        double hitPos = (ballX - paddleX - paddleWidth / 2) / (paddleWidth / 2);
        ballVX += hitPos;
        ballVX = ballVX.clamp(-6, 6);
      }

      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col < colCount; col++) {
          if (!bricks[row][col]) continue;
          double brickWidth = (width - (colCount + 1) * brickGap) / colCount;
          double brickLeft = col * (brickWidth + brickGap) + brickGap;
          double brickTop = row * (brickHeight + brickGap) + brickGap + 20;
          Rect brickRect = Rect.fromLTWH(
            brickLeft,
            brickTop,
            brickWidth,
            brickHeight,
          );
          Rect ballRect = Rect.fromCircle(
            center: Offset(ballX, ballY),
            radius: ballRadius,
          );
          if (ballRect.overlaps(brickRect)) {
            bricks[row][col] = false;
            ballVY = -ballVY;
            // High score update
            int score = _calculateScore();
            if (score > highScore) {
              highScore = score;
              _saveHighScore();
            }
            if (bricks.every((row) => row.every((b) => !b))) {
              // All bricks cleared: generate new random layer and increase difficulty
              final rand = Random();
              bricks = List.generate(rowCount, (row) {
                // Generate a random row with a bias towards true
                List<bool> brickRow = List.generate(
                  colCount,
                  (_) => rand.nextDouble() < 0.7,
                );
                // Ensure at least one brick per row
                if (!brickRow.contains(true)) {
                  brickRow[rand.nextInt(colCount)] = true;
                }
                return brickRow;
              });
              // Optionally, increase ball speed for challenge
              ballVX *= 1.05;
              ballVY *= 1.05;
            }
            return;
          }
        }
      }

      if (ballY - ballRadius > height) {
        isPlaying = false;
        isGameOver = true;
        gameTimer?.cancel();
      }
    });
  }

  void _movePaddleTo(double dx, double width) {
    setState(() {
      paddleX = dx - paddleWidth / 2;
      paddleX = paddleX.clamp(0, width - paddleWidth);
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonBlue = const Color(0xFF00FFF7);
    final neonOrange = const Color(0xFFFFA500);
    final neonGreen = const Color(0xFF39FF14);
    final neonRed = const Color(0xFFFF073A);
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Brick Breaker',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFF00FFF7),
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
          IconButton(
            icon: Icon(Icons.refresh, color: neonGreen),
            onPressed: () => _startGame(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            double paddleTop = height - paddleHeight - 20;
            if (bricks.isEmpty ||
                lastSize == null ||
                lastSize!.width != width ||
                lastSize!.height != height) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    lastSize = Size(width, height);
                    _initializeGameState(width, height);
                  });
                }
              });
              return const Scaffold(
                backgroundColor: Color(0xFF18122B),
                body: Center(child: CircularProgressIndicator()),
              );
            }
            int score = _calculateScore();
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (isPlaying) {
                  _movePaddleTo(details.localPosition.dx, width);
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  ..._buildBricks(width, neonOrange),
                  Positioned(
                    left: paddleX,
                    top: paddleTop,
                    child: Container(
                      width: paddleWidth,
                      height: paddleHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: neonBlue, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: neonBlue.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: ballX - ballRadius,
                    top: ballY - ballRadius,
                    child: Container(
                      width: ballRadius * 2,
                      height: ballRadius * 2,
                      decoration: BoxDecoration(
                        color: neonRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: neonRed.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  if (isGameOver || isGameWon)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: neonBlue, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: neonBlue.withOpacity(0.4),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isGameWon ? 'You Win!' : 'Game Over',
                              style: TextStyle(
                                fontSize: 32,
                                fontFamily: 'Orbitron',
                                color: isGameWon ? neonGreen : neonRed,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: (isGameWon ? neonGreen : neonRed)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _neonButton(
                              'Restart',
                              () => _startGame(width, height),
                              isGameWon ? neonGreen : neonRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBricks(double width, Color neonOrange) {
    List<Widget> widgets = [];
    double brickWidth = (width - (colCount + 1) * brickGap) / colCount;
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        if (!bricks[row][col]) continue;
        double left = col * (brickWidth + brickGap) + brickGap;
        double top = row * (brickHeight + brickGap) + brickGap + 20;
        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: brickWidth,
              height: brickHeight,
              decoration: BoxDecoration(
                color: neonOrange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: neonOrange.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return widgets;
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
