import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SpaceWarGame extends StatefulWidget {
  const SpaceWarGame({super.key});

  @override
  State<SpaceWarGame> createState() => _SpaceWarGameState();
}

class _SpaceWarGameState extends State<SpaceWarGame> {
  static const int rowCount = 5;
  static const int colCount = 8;
  static const double enemySize = 32;
  static const double playerWidth = 48;
  static const double playerHeight = 24;
  static const double bulletWidth = 6;
  static const double bulletHeight = 16;
  static const double enemyGap = 18;
  static const double moveStep = 16;
  static const double bulletSpeed = 16;
  static const double enemySpeed = 0.2;
  static const double enemyDescend = 6;

  double playerX = 0;
  List<Bullet> playerBullets = [];
  List<Bullet> enemyBullets = [];
  List<List<bool>> enemies = [];
  double enemyOffsetX = 0;
  double enemyOffsetY = 0;
  int enemyDir = 1; // 1: right, -1: left
  int score = 0;
  bool isGameOver = false;
  bool isStarted = false;
  Timer? gameTimer;
  double screenWidth = 0;
  double screenHeight = 0;

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      playerX = 0;
      playerBullets = [];
      enemyBullets = [];
      enemies = List.generate(rowCount, (_) => List.filled(colCount, true));
      enemyOffsetX = 0;
      enemyOffsetY = -screenHeight / 3;
      enemyDir = 1;
      score = 0;
      isGameOver = false;
      isStarted = true;
    });
    gameTimer?.cancel();
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(),
    );
  }

  void _endGame() {
    setState(() {
      isGameOver = true;
      isStarted = false;
    });
    gameTimer?.cancel();
  }

  void _tick() {
    setState(() {
      // Move player bullets
      for (final bullet in playerBullets) {
        bullet.y -= bulletSpeed;
      }
      playerBullets.removeWhere((b) => b.y < -screenHeight / 2);
      // Move enemy bullets
      for (final bullet in enemyBullets) {
        bullet.y += bulletSpeed;
      }
      enemyBullets.removeWhere((b) => b.y > screenHeight / 2);
      // Move enemies
      double minX = double.infinity, maxX = -double.infinity;
      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col < colCount; col++) {
          if (!enemies[row][col]) continue;
          double x = enemyOffsetX + col * (enemySize + enemyGap);
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
      if (minX + enemyDir * enemySpeed < -screenWidth / 2 + 8 ||
          maxX + enemyDir * enemySpeed > screenWidth / 2 - enemySize - 8) {
        enemyDir *= -1;
        enemyOffsetY += enemyDescend;
      } else {
        enemyOffsetX += enemyDir * enemySpeed;
      }
      // Enemy shooting
      if (Random().nextDouble() < 0.02) {
        List<int> shooters = [];
        for (int col = 0; col < colCount; col++) {
          for (int row = rowCount - 1; row >= 0; row--) {
            if (enemies[row][col]) {
              shooters.add(col);
              break;
            }
          }
        }
        if (shooters.isNotEmpty) {
          int col = shooters[Random().nextInt(shooters.length)];
          int row = rowCount - 1;
          while (row >= 0 && !enemies[row][col]) row--;
          if (row >= 0) {
            double ex =
                enemyOffsetX + col * (enemySize + enemyGap) + enemySize / 2;
            double ey = enemyOffsetY + row * (enemySize + enemyGap) + enemySize;
            enemyBullets.add(Bullet(ex, ey, false));
          }
        }
      }
      // Bullet-enemy collision
      for (final bullet in playerBullets) {
        for (int row = 0; row < rowCount; row++) {
          for (int col = 0; col < colCount; col++) {
            if (!enemies[row][col]) continue;
            double ex = enemyOffsetX + col * (enemySize + enemyGap);
            double ey = enemyOffsetY + row * (enemySize + enemyGap);
            Rect enemyRect = Rect.fromLTWH(
              ex + screenWidth / 2,
              ey + 80,
              enemySize,
              enemySize,
            );
            Rect bulletRect = Rect.fromCenter(
              center: Offset(bullet.x + screenWidth / 2, bullet.y + 80),
              width: bulletWidth,
              height: bulletHeight,
            );
            if (bulletRect.overlaps(enemyRect)) {
              enemies[row][col] = false;
              bullet.hit = true;
              score += 10;
            }
          }
        }
      }
      playerBullets.removeWhere((b) => b.hit);
      // Bullet-player collision
      double playerY = screenHeight - playerHeight - 24;
      Rect playerRect = Rect.fromLTWH(
        (screenWidth - playerWidth) / 2 + playerX,
        playerY,
        playerWidth,
        playerHeight,
      );
      for (final bullet in enemyBullets) {
        Rect bulletRect = Rect.fromCenter(
          center: Offset(bullet.x + screenWidth / 2, bullet.y + 80),
          width: bulletWidth,
          height: bulletHeight,
        );
        if (bulletRect.overlaps(playerRect)) {
          _endGame();
          return;
        }
      }
      // Enemy-player collision or enemies reach bottom
      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col < colCount; col++) {
          if (!enemies[row][col]) continue;
          double ey = enemyOffsetY + row * (enemySize + enemyGap) + enemySize;
          if (ey + 80 > playerY) {
            _endGame();
            return;
          }
        }
      }
      // Win
      if (enemies.every((row) => row.every((e) => !e))) {
        _endGame();
      }
    });
  }

  void _movePlayer(int dir) {
    setState(() {
      playerX += dir * moveStep;
      // Clamp so the ship stays within the screen
      playerX = playerX.clamp(
        -(screenWidth - playerWidth) / 2,
        (screenWidth - playerWidth) / 2,
      );
    });
  }

  void _shoot() {
    if (!isStarted || isGameOver) return;
    double playerY = screenHeight - playerHeight - 24;
    // Bullet x is relative to the center
    playerBullets.add(Bullet(playerX, playerY, true));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF39FF14);
    final neonBlue = const Color(0xFF00FFF7);
    final neonPink = const Color(0xFFFF00FF);
    final neonRed = const Color(0xFFFF073A);
    final neonYellow = const Color(0xFFFFFF00);
    return LayoutBuilder(
      builder: (context, constraints) {
        screenWidth = constraints.maxWidth;
        screenHeight = constraints.maxHeight;
        return Scaffold(
          backgroundColor: const Color(0xFF18122B),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Space War',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Color(0xFF00FFF7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: (enemies.isEmpty)
              ? Center(
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
                          isGameOver ? 'Game Over' : 'Space War',
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'Orbitron',
                            color: isGameOver ? neonRed : neonBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _neonButton(
                          isGameOver ? 'Restart' : 'Start',
                          _startGame,
                          neonGreen,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Enemies
                    ..._buildEnemies(neonPink, neonGreen),
                    // Player
                    Positioned(
                      left: (screenWidth - playerWidth) / 2 + playerX,
                      top: screenHeight - playerHeight - 24,
                      child: _buildPlayer(neonBlue, neonYellow),
                    ),
                    // Bullets
                    ...playerBullets.map((b) => _buildBullet(b, neonGreen)),
                    ...enemyBullets.map((b) => _buildBullet(b, neonRed)),
                    // Score
                    Positioned(
                      top: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Score: $score',
                          style: TextStyle(
                            fontSize: 28,
                            fontFamily: 'Orbitron',
                            color: neonYellow,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: neonYellow.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Controls
                    if (!isGameOver && isStarted)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _controlButton(
                                Icons.arrow_left,
                                () => _movePlayer(-1),
                                neonBlue,
                              ),
                              const SizedBox(width: 32),
                              _controlButton(
                                Icons.arrow_upward,
                                _shoot,
                                neonGreen,
                              ),
                              const SizedBox(width: 32),
                              _controlButton(
                                Icons.arrow_right,
                                () => _movePlayer(1),
                                neonPink,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Start/Game Over
                    if (!isStarted || isGameOver)
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
                                isGameOver ? 'Game Over' : 'Space War',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontFamily: 'Orbitron',
                                  color: isGameOver ? neonRed : neonBlue,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _neonButton(
                                isGameOver ? 'Restart' : 'Start',
                                _startGame,
                                neonGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  List<Widget> _buildEnemies(Color color, Color altColor) {
    List<Widget> widgets = [];
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        if (!enemies[row][col]) continue;
        double ex = enemyOffsetX + col * (enemySize + enemyGap);
        double ey = enemyOffsetY + row * (enemySize + enemyGap);
        widgets.add(
          Positioned(
            left: ex + screenWidth / 2,
            top: ey + 80,
            child: Container(
              width: enemySize,
              height: enemySize,
              decoration: BoxDecoration(
                color: (row % 2 == 0) ? color : altColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(Icons.android, color: Colors.white, size: 22),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildPlayer(Color color, Color accent) {
    return Container(
      width: playerWidth,
      height: playerHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(Icons.flight, color: accent, size: 28),
    );
  }

  Widget _buildBullet(Bullet b, Color color) {
    return Positioned(
      left: b.x + screenWidth / 2 - bulletWidth / 2,
      top: b.y + 80 - bulletHeight / 2,
      child: Container(
        width: bulletWidth,
        height: bulletHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onPressed,
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

class Bullet {
  double x;
  double y;
  bool fromPlayer;
  bool hit = false;
  Bullet(this.x, this.y, this.fromPlayer);
}
