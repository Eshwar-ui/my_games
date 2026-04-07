import 'package:flutter/material.dart';
import 'dart:async' as async;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

import '../services/arcade_stats_service.dart';
import '../services/game_haptics.dart';
import '../services/game_help.dart';
import '../services/haptic_arcade_button.dart';

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
  static const String _atlasAsset = 'brick_breaker/sprite_sheet.png';

  late final Future<_BrickSpriteAtlas> _atlasFuture;

  double paddleX = 0;
  double ballX = 0;
  double ballY = 0;
  double ballVX = 3;
  double ballVY = -3;
  List<List<bool>> bricks = [];
  bool isPlaying = false;
  bool isGameOver = false;
  async.Timer? gameTimer;
  Size? lastSize;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    GameHaptics.preload();
    // So Flame can load `assets/<path>` correctly.
    Flame.images.prefix = 'assets/';
    _atlasFuture = _loadAtlas();
    _loadHighScore();
  }

  Future<_BrickSpriteAtlas> _loadAtlas() async {
    final image = await Flame.images.load(_atlasAsset);

    // Crop by detecting alpha coverage columns, so it works even if the sheet
    // isn't perfectly evenly spaced.
    final spriteRects = await _detectSpriteRects(image);
    spriteRects.sort((a, b) => a.left.compareTo(b.left));

    Sprite spriteFromRect(Rect rect) {
      return Sprite(
        image,
        srcPosition: Vector2(rect.left, rect.top),
        srcSize: Vector2(rect.width, rect.height),
      );
    }

    if (spriteRects.length < 3) {
      throw StateError(
        'brick_breaker sprite sheet detection failed: expected >=3 sprites, got ${spriteRects.length}',
      );
    }

    final paddle = spriteFromRect(spriteRects[0]);
    final ball = spriteFromRect(spriteRects[1]);

    final brickVariantRects = spriteRects.sublist(2);
    final brickVariants = brickVariantRects.map(spriteFromRect).toList();
    return _BrickSpriteAtlas(
      paddle: paddle,
      ball: ball,
      brickVariants: brickVariants.isEmpty ? [paddle] : brickVariants,
    );
  }

  Future<List<Rect>> _detectSpriteRects(ui.Image image) async {
    const alphaThreshold = 10; // ignore very faint glow speckles
    const minSpriteWidth = 25;
    const gapMergeColumns = 3; // merge runs separated by tiny transparent gaps
    const padding = 2; // add a little padding so glow isn't clipped

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return [];
    final bytes = byteData.buffer.asUint8List();

    final width = image.width;
    final height = image.height;

    bool alphaAt(int x, int y) {
      final idx = (y * width + x) * 4 + 3;
      return bytes[idx] > alphaThreshold;
    }

    // Step 1: detect columns that have any visible pixels.
    final columnHas = List<bool>.filled(width, false);
    for (int x = 0; x < width; x++) {
      bool any = false;
      for (int y = 0; y < height; y++) {
        if (alphaAt(x, y)) {
          any = true;
          break;
        }
      }
      columnHas[x] = any;
    }

    // Step 2: convert column runs into initial segments.
    final segments = <({int left, int right})>[];
    int? start;
    for (int x = 0; x < width; x++) {
      if (columnHas[x]) {
        start ??= x;
      } else if (start != null) {
        segments.add((left: start, right: x - 1));
        start = null;
      }
    }
    if (start != null) segments.add((left: start, right: width - 1));

    // Step 3: filter tiny runs and merge near-by runs (anti-aliasing gaps).
    final filtered = segments
        .where((s) => s.right - s.left + 1 >= minSpriteWidth)
        .toList();

    final merged = <({int left, int right})>[];
    for (final seg in filtered) {
      if (merged.isEmpty) {
        merged.add(seg);
        continue;
      }
      final last = merged.removeLast();
      final gap = seg.left - last.right - 1;
      if (gap <= gapMergeColumns) {
        merged.add((left: last.left, right: seg.right));
      } else {
        merged.add(last);
        merged.add(seg);
      }
    }

    // Step 4: compute y bounds for each merged x-run.
    final rects = <Rect>[];
    for (final seg in merged) {
      int top = height;
      int bottom = -1;

      for (int y = 0; y < height; y++) {
        bool any = false;
        for (int x = seg.left; x <= seg.right; x++) {
          if (alphaAt(x, y)) {
            any = true;
            break;
          }
        }
        if (any) {
          top = min(top, y);
          bottom = max(bottom, y);
        }
      }

      if (bottom < 0) continue;

      final left = (seg.left - padding).clamp(0, width - 1);
      final right = (seg.right + padding).clamp(0, width - 1);
      final t = (top - padding).clamp(0, height - 1);
      final b = (bottom + padding).clamp(0, height - 1);

      rects.add(
        Rect.fromLTRB(
          left.toDouble(),
          t.toDouble(),
          (right + 1).toDouble(),
          (b + 1).toDouble(),
        ),
      );
    }

    return rects;
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
    gameTimer?.cancel();
    gameTimer = async.Timer.periodic(
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
    ArcadeStatsService.recordPlay('brick_breaker');
    setState(() {
      _initializeGameState(width, height);
    });
  }

  void _updateGame(double width, double height) {
    if (!isPlaying) return;
    var shouldSaveHighScore = false;
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
        GameHaptics.light();
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
              shouldSaveHighScore = true;
            }
            GameHaptics.medium();
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
        ArcadeStatsService.recordResult(
          'brick_breaker',
          score: _calculateScore(),
          won: false,
        );
        GameHaptics.heavy();
      }
    });
    if (shouldSaveHighScore) {
      _saveHighScore();
    }
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
          const GameHelpAction(
            title: 'Brick Breaker',
            accent: Color(0xFFFFA500),
            steps: [
              'Drag left and right to move the paddle.',
              'Bounce the ball to break every brick you can reach.',
              'Do not let the ball drop below the paddle.',
            ],
            tip: 'Use the paddle edges to change the bounce angle and recover control.',
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
          IconButton(
            icon: Icon(Icons.refresh, color: neonGreen),
            onPressed: () {
              GameHaptics.tap();
              final size = lastSize ?? MediaQuery.sizeOf(context);
              _startGame(size.width, size.height);
            },
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: FutureBuilder<_BrickSpriteAtlas>(
        future: _atlasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load sprites'));
          }
          final atlas = snapshot.data!;

          return SafeArea(
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
                  return const Center(child: CircularProgressIndicator());
                }

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (isPlaying) {
                      _movePaddleTo(details.localPosition.dx, width);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      ..._buildBricks(width, atlas),
                      Positioned(
                        left: paddleX,
                        top: paddleTop,
                        child: _spriteBox(
                          sprite: atlas.paddle,
                          width: paddleWidth,
                          height: paddleHeight,
                        ),
                      ),
                      Positioned(
                        left: ballX - ballRadius,
                        top: ballY - ballRadius,
                        child: _spriteBox(
                          sprite: atlas.ball,
                          width: ballRadius * 2,
                          height: ballRadius * 2,
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
                                  'Game Over',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontFamily: 'Orbitron',
                                    color: neonRed,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: neonRed.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _neonButton(
                                  'Restart',
                                  () => _startGame(width, height),
                                  neonRed,
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
          );
        },
      ),
    );
  }

  List<Widget> _buildBricks(double width, _BrickSpriteAtlas atlas) {
    List<Widget> widgets = [];
    double brickWidth = (width - (colCount + 1) * brickGap) / colCount;
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        if (!bricks[row][col]) continue;
        double left = col * (brickWidth + brickGap) + brickGap;
        double top = row * (brickHeight + brickGap) + brickGap + 20;
        final brickSprite = atlas.brickForRow(row);
        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: _spriteBox(
              sprite: brickSprite,
              width: brickWidth,
              height: brickHeight,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _neonButton(String text, VoidCallback onPressed, Color color) {
    return ArcadeButton(label: text, color: color, onPressed: onPressed);
  }
}

class _BrickSpriteAtlas {
  const _BrickSpriteAtlas({
    required this.paddle,
    required this.ball,
    required this.brickVariants,
  });

  final Sprite paddle;
  final Sprite ball;
  final List<Sprite> brickVariants;

  Sprite brickForRow(int row) => brickVariants[row % brickVariants.length];
}

Widget _spriteBox({
  required Sprite sprite,
  required double width,
  required double height,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: _SpritePainter(sprite),
      size: Size(width, height),
    ),
  );
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.sprite);

  final Sprite sprite;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      sprite.srcPosition.x,
      sprite.srcPosition.y,
      sprite.srcSize.x,
      sprite.srcSize.y,
    );
    final dst = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(sprite.image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.sprite.image != sprite.image ||
        oldDelegate.sprite.srcPosition != sprite.srcPosition ||
        oldDelegate.sprite.srcSize != sprite.srcSize;
  }
}
