import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/arcade_stats_service.dart';
import '../services/game_haptics.dart';
import '../services/game_help.dart';
import '../services/haptic_arcade_button.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../widgets/game_pause_overlay.dart';

class NeonRacer extends StatefulWidget {
  const NeonRacer({super.key});

  @override
  State<NeonRacer> createState() => _NeonRacerState();
}

class _NeonRacerState extends State<NeonRacer> with TickerProviderStateMixin {
  // Game state
  double playerLane = 1.0; // 0, 1, or 2
  List<_Obstacle> obstacles = [];
  Timer? gameTimer;
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;
  int score = 0;
  int highScore = 0;
  double speed = 5.0;
  DateTime? lastSpawnTime;
  // Individual car images: [player, enemy1, enemy2, enemy3]
  List<ui.Image?> carImages = [null, null, null, null];
  bool spritesLoaded = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    GameHaptics.preload();
    _loadHighScore();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadSprites();
  }

  Future<void> _loadSprites() async {
    final paths = [
      'assets/neon_racer/player_car.png',
      'assets/neon_racer/enemy_car_1.png',
      'assets/neon_racer/enemy_car_2.png',
      'assets/neon_racer/enemy_car_3.png',
    ];
    for (int i = 0; i < paths.length; i++) {
      final data = await rootBundle.load(paths[i]);
      final bytes = data.buffer.asUint8List();
      carImages[i] = await decodeImageFromList(bytes);
    }
    setState(() {
      spritesLoaded = true;
    });
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('neon_racer_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('neon_racer_high_score', highScore);
  }

  void _startGame() {
    ArcadeStatsService.recordPlay('neon_racer');
    setState(() {
      playerLane = 1.0;
      obstacles = [];
      score = 0;
      speed = 5.0;
      isGameOver = false;
      isStarted = true;
      isPaused = false;
      lastSpawnTime = DateTime.now();
    });
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) => _update());
  }

  void _update() {
    if (!isStarted || isGameOver || isPaused) return;

    setState(() {
      // Move obstacles
      for (var obstacle in obstacles) {
        obstacle.y += speed;
      }

      // Remove off-screen obstacles
      obstacles.removeWhere((o) => o.y > 800);

      // Spawn new obstacles
      final now = DateTime.now();
      if (lastSpawnTime == null || now.difference(lastSpawnTime!).inMilliseconds > (1500 - speed * 50).clamp(500, 1500)) {
        obstacles.add(_Obstacle(lane: Random().nextInt(3), type: Random().nextInt(3)));
        lastSpawnTime = now;
      }

      // Check collisions
      for (var obstacle in obstacles) {
        if (obstacle.lane == playerLane.round() && obstacle.y > 550 && obstacle.y < 650) {
          _endGame();
          return;
        }
      }

      // Increment score
      score++;
      if (score % 500 == 0) {
        speed += 0.5;
        GameHaptics.light();
      }
    });
  }

  void _endGame() {
    ArcadeStatsService.recordResult('neon_racer', score: score, won: false);
    setState(() {
      isGameOver = true;
      isStarted = false;
    });
    gameTimer?.cancel();
    GameHaptics.heavy();
    if (score > highScore) {
      setState(() {
        highScore = score;
      });
      _saveHighScore();
    }
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

  void _moveLeft() {
    if (isPaused) return;
    if (playerLane > 0) {
      setState(() {
        playerLane--;
      });
      GameHaptics.tap();
    }
  }

  void _moveRight() {
    if (isPaused) return;
    if (playerLane < 2) {
      setState(() {
        playerLane++;
      });
      GameHaptics.tap();
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF00FFF7);
    const neonRed = Color(0xFFFF073A);
    const neonPurple = Color(0xFF9D00FF);

    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        title: const Text('Neon Racer'),
        actions: [
          const GameHelpAction(
            title: 'Neon Racer',
            accent: neonBlue,
            steps: [
              'Swipe left or right to change lanes.',
              'Avoid obstacles and keep your speed up!',
              'Game gets faster every 500 points.',
            ],
            tip: 'Focus on the gap between cars, not the cars themselves.',
          ),
          if (isStarted && !isGameOver)
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              color: neonBlue,
              onPressed: _togglePause,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'High: $highScore',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: neonPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background "Road"
          Positioned.fill(
            child: Row(
              children: List.generate(3, (index) => Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                      right: index == 2 ? BorderSide(color: Colors.white.withOpacity(0.05), width: 1) : BorderSide.none,
                    ),
                  ),
                ),
              )),
            ),
          ),

          // Obstacles
          ...obstacles.map((o) => Positioned(
            left: MediaQuery.of(context).size.width / 3 * o.lane + 10,
            top: o.y,
            width: MediaQuery.of(context).size.width / 3 - 20,
            height: 160,
            child: (!spritesLoaded || carImages[o.type + 1] == null)
              ? Container(
                  decoration: BoxDecoration(
                    color: neonRed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: neonRed, width: 2),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: neonRed),
                )
              : CustomPaint(
                  painter: _CarPainter(image: carImages[o.type + 1]!),
                ),
          )),

          // Player Car
          Positioned(
            left: MediaQuery.of(context).size.width / 3 * playerLane + 10,
            top: 580,
            width: MediaQuery.of(context).size.width / 3 - 20,
            height: 160,
            child: (!spritesLoaded || carImages[0] == null)
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: neonBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.rocket_rounded, color: Colors.white, size: 50)),
                )
              : CustomPaint(
                  painter: _CarPainter(image: carImages[0]!),
                ),
          ),

          // Controls (Invisible Overlay)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _moveLeft,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _moveRight,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
              ],
            ),
          ),

          // Score Overlay
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: neonBlue.withOpacity(0.5)),
                ),
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Orbitron',
                    color: neonBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Start / Game Over Screens
          if (!isStarted || isGameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGameOver)
                      const Text(
                        'CRASHED!',
                        style: TextStyle(
                          fontSize: 48,
                          fontFamily: 'Orbitron',
                          color: neonRed,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      isGameOver ? 'Final Score: $score' : 'Neon Racer',
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Orbitron',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ArcadeButton(
                      label: isGameOver ? 'Try Again' : 'Start Engine',
                      color: neonBlue,
                      onPressed: _startGame,
                    ),
                  ],
                ),
              ),
            ),
          if (isPaused)
            GamePauseOverlay(
              onResume: _resume,
              onRestart: _startGame,
              onQuit: () => Navigator.of(context).pop(),
              accentColor: const Color(0xFF00FFF7),
            ),
        ],
      ),
    );
  }
}

class _Obstacle {
  final int lane;
  final int type;
  double y = -100;

  _Obstacle({required this.lane, this.type = 0});
}

// Simple painter that draws a full image, maintaining aspect ratio
class _CarPainter extends CustomPainter {
  final ui.Image image;

  _CarPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();

    // Source: the entire image (no cropping needed!)
    final src = Rect.fromLTWH(0, 0, imgW, imgH);

    // Maintain original aspect ratio
    final double imgRatio = imgW / imgH;
    double dstW, dstH;

    if (size.width / size.height > imgRatio) {
      // Widget is wider than image ratio -> fit by height
      dstH = size.height;
      dstW = dstH * imgRatio;
    } else {
      // Widget is narrower -> fit by width
      dstW = size.width;
      dstH = dstW / imgRatio;
    }

    // Center in the widget
    final dst = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: dstW,
      height: dstH,
    );

    final paint = Paint()..filterQuality = ui.FilterQuality.medium;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) =>
      oldDelegate.image != image;
}
