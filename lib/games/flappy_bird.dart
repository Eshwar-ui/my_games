import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/arcade_stats_service.dart';
import '../services/game_haptics.dart';
import '../services/game_help.dart';
import '../services/haptic_arcade_button.dart';

class FlappyBirdGame extends StatefulWidget {
  const FlappyBirdGame({super.key});

  @override
  State<FlappyBirdGame> createState() => _FlappyBirdGameState();
}

class _FlappyBirdGameState extends State<FlappyBirdGame> {
  static const String _highScoreKey = 'flappy_bird_high_score';
  static const double gravity = 0.6;
  static const double flapPower = -9.5;
  static const double birdWidth = 48;
  static const double birdHeight = 36;
  static const double pipeWidth = 60;
  static const double gap = 160;
  static const int pipeInterval = 1200; // ms

  double birdY = 0;
  double birdVY = 0;
  double baseY = 0;
  List<Pipe> pipes = [];
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isStarted = false;
  Timer? gameTimer;
  Timer? pipeTimer;
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    GameHaptics.preload();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      highScore = prefs.getInt(_highScoreKey) ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, highScore);
  }

  void _startGame() {
    ArcadeStatsService.recordPlay('flappy_bird');
    setState(() {
      birdY = 0;
      birdVY = 0;
      pipes = [];
      score = 0;
      isGameOver = false;
      isStarted = true;
    });
    gameTimer?.cancel();
    pipeTimer?.cancel();
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(),
    );
    pipeTimer = Timer.periodic(
      const Duration(milliseconds: pipeInterval),
      (_) => _addPipe(),
    );
  }

  void _endGame() {
    final shouldPersistHighScore = score > highScore;
    ArcadeStatsService.recordResult('flappy_bird', score: score, won: false);
    setState(() {
      isGameOver = true;
      isStarted = false;
      if (shouldPersistHighScore) {
        highScore = score;
      }
    });
    gameTimer?.cancel();
    pipeTimer?.cancel();
    GameHaptics.heavy();
    if (shouldPersistHighScore) {
      _saveHighScore();
    }
  }

  void _tick() {
    if (!isStarted || isGameOver) return;

    final previousScore = score;
    final nextBirdVY = birdVY + gravity;
    final nextBirdY = birdY + nextBirdVY;
    final updatedPipes = <Pipe>[];
    var nextScore = score;
    var shouldEndGame = false;

    for (final pipe in pipes) {
      final updatedPipe = Pipe(pipe.x - 3, pipe.centerY)..passed = pipe.passed;
      if (updatedPipe.x + pipeWidth < -screenWidth / 2) {
        continue;
      }

      if (_collides(updatedPipe, nextBirdY)) {
        shouldEndGame = true;
      }

      if (!updatedPipe.passed && updatedPipe.x + pipeWidth < 0) {
        updatedPipe.passed = true;
        nextScore++;
      }

      updatedPipes.add(updatedPipe);
    }

    if (nextBirdY + birdHeight / 2 > baseY ||
        nextBirdY - birdHeight / 2 < -screenHeight / 2) {
      shouldEndGame = true;
    }

    setState(() {
      birdVY = nextBirdVY;
      birdY = nextBirdY;
      pipes = updatedPipes;
      score = nextScore;
    });
    if (nextScore > previousScore) {
      GameHaptics.light();
    }

    if (shouldEndGame) {
      _endGame();
    }
  }

  void _addPipe() {
    final rand = Random();
    final centerY =
        rand.nextDouble() * (screenHeight - gap - 120) +
        gap / 2 +
        60 -
        screenHeight / 2;
    pipes.add(Pipe(screenWidth / 2, centerY));
  }

  bool _collides(Pipe pipe, double birdPositionY) {
    // Bird rect
    final birdRect = Rect.fromCenter(
      center: Offset(0, birdPositionY),
      width: birdWidth,
      height: birdHeight,
    );
    // Top pipe
    final topRect = Rect.fromLTWH(
      pipe.x - pipeWidth / 2,
      -screenHeight / 2,
      pipeWidth,
      pipe.centerY - gap / 2,
    );
    // Bottom pipe
    final bottomRect = Rect.fromLTWH(
      pipe.x - pipeWidth / 2,
      pipe.centerY + gap / 2,
      pipeWidth,
      screenHeight / 2 - (pipe.centerY + gap / 2),
    );
    return birdRect.overlaps(topRect) || birdRect.overlaps(bottomRect);
  }

  void _flap() {
    if (!isStarted) {
      _startGame();
      GameHaptics.tap();
      return;
    }
    if (isGameOver) return;
    setState(() {
      birdVY = flapPower;
    });
    GameHaptics.tap();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    pipeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonYellow = const Color(0xFFFFFF00);
    final neonGreen = const Color(0xFF39FF14);
    final neonBlue = const Color(0xFF00FFF7);
    final neonPink = const Color(0xFFFF00FF);
    final neonRed = const Color(0xFFFF073A);
    return LayoutBuilder(
      builder: (context, constraints) {
        screenHeight = constraints.maxHeight;
        screenWidth = constraints.maxWidth;
        baseY = screenHeight / 2 - 40;
        return Scaffold(
          backgroundColor: const Color(0xFF18122B),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Flappy Bird',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Color(0xFFFFFF00),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              const GameHelpAction(
                title: 'Flappy Bird',
                accent: Color(0xFFFFFF00),
                steps: [
                  'Tap anywhere to flap upward.',
                  'Pass cleanly through pipe gaps to score points.',
                  'Avoid pipes, the ceiling, and the floor.',
                ],
                tip: 'Short rhythmic taps are steadier than panic flapping.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Center(
                  child: Text(
                    'High: $highScore',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Orbitron',
                      color: Color(0xFF00FFF7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Color(0xFF00FFF7), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _flap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pipes
                ...pipes.map((pipe) => _buildPipe(pipe, neonGreen, neonPink)),
                // Bird
                Positioned(
                  left: (screenWidth - birdWidth) / 2,
                  top: baseY + birdY - birdHeight / 2,
                  child: _buildBird(neonYellow, neonBlue, neonRed),
                ),
                // Score
                Positioned(
                  top: 32,
                  child: Text(
                    'Score: $score',
                    style: TextStyle(
                      fontSize: 32,
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
                if (isGameOver)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: neonPink, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: neonPink.withOpacity(0.4),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Game Over',
                            style: TextStyle(
                              fontSize: 32,
                              fontFamily: 'Orbitron',
                              color: Color(0xFFFF073A),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _neonButton('Restart', _startGame, neonGreen),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBird(Color body, Color wing, Color beak) {
    return Container(
      width: birdWidth,
      height: birdHeight,
      decoration: BoxDecoration(
        color: body,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: body.withOpacity(0.7),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: birdWidth * 0.7,
            top: birdHeight * 0.45,
            child: Container(
              width: birdWidth * 0.18,
              height: birdHeight * 0.12,
              decoration: BoxDecoration(
                color: beak,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: birdWidth * 0.18,
            top: birdHeight * 0.32,
            child: Container(
              width: birdWidth * 0.13,
              height: birdHeight * 0.13,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: birdWidth * 0.13,
            top: birdHeight * 0.37,
            child: Container(
              width: birdWidth * 0.07,
              height: birdHeight * 0.07,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: birdWidth * 0.2,
            top: birdHeight * 0.7,
            child: Container(
              width: birdWidth * 0.3,
              height: birdHeight * 0.18,
              decoration: BoxDecoration(
                color: wing,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipe(Pipe pipe, Color color, Color altColor) {
    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: screenWidth / 2 + pipe.x - pipeWidth / 2,
          top: 0,
          child: Container(
            width: pipeWidth,
            height: baseY + pipe.centerY - gap / 2,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        // Bottom pipe
        Positioned(
          left: screenWidth / 2 + pipe.x - pipeWidth / 2,
          top: baseY + pipe.centerY + gap / 2,
          child: Container(
            width: pipeWidth,
            height: screenHeight - (baseY + pipe.centerY + gap / 2),
            decoration: BoxDecoration(
              color: altColor.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: altColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _neonButton(String text, VoidCallback onPressed, Color color) {
    return ArcadeButton(label: text, color: color, onPressed: onPressed);
  }
}

class Pipe {
  double x;
  double centerY;
  bool passed;
  Pipe(this.x, this.centerY) : passed = false;
}
