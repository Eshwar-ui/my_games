import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/arcade_button.dart';

class SpaceWarGame extends StatefulWidget {
  const SpaceWarGame({super.key});

  @override
  State<SpaceWarGame> createState() => _SpaceWarGameState();
}

class _SpaceWarGameState extends State<SpaceWarGame> {
  static const String _atlasAsset = 'space_war/space_war_sprites.png';
  static const String _highScoreKey = 'space_war_high_score';
  static const double playerWidth = 82;
  static const double playerHeight = 48;
  static const double bulletWidth = 6;
  static const double bulletHeight = 16;
  static const double moveStep = 18;
  static const double playerBulletSpeed = 10;
  static const double enemyBulletSpeed = 6.5;
  static const int moveRepeatMs = 70;
  static const int shootRepeatMs = 150;
  // Controls are rendered as a multi-line panel (icons + hint text).
  // This value is used to position the player above the panel.
  static const double controlPanelHeight = 220;
  static const int tickMs = 16;

  final Random _random = Random();

  late final Future<_SpriteAtlas> _atlasFuture;

  double playerX = 0;
  List<EnemyShip> enemies = [];
  List<Bullet> playerBullets = [];
  List<Bullet> enemyBullets = [];
  List<ExplosionBurst> bursts = [];
  int score = 0;
  int highScore = 0;
  int wave = 0;
  int enemiesRemainingToSpawn = 0;
  double spawnCooldownMs = 0;
  bool isGameOver = false;
  bool isStarted = false;
  async.Timer? gameTimer;
  async.Timer? _moveRepeatTimer;
  async.Timer? _shootRepeatTimer;
  double screenWidth = 0;
  double screenHeight = 0;

  @override
  void initState() {
    super.initState();
    // Flame's default image prefix is `assets/images/`, but this project stores
    // sprites under `assets/space_war/...`. Align the prefix so the loader can
    // find the sprite sheet.
    Flame.images.prefix = 'assets/';
    _atlasFuture = _loadAtlas();
    _loadHighScore();
  }

  Future<_SpriteAtlas> _loadAtlas() async {
    final image = await Flame.images.load(_atlasAsset);

    Sprite spriteFromRect(Rect rect) {
      return Sprite(
        image,
        srcPosition: Vector2(rect.left, rect.top),
        srcSize: Vector2(rect.width, rect.height),
      );
    }

    return _SpriteAtlas(
      // This sheet has large transparent padding inside each visual grid cell,
      // so use tight source rects instead of whole-cell slicing.
      playerIdle: spriteFromRect(const Rect.fromLTWH(215, 330, 235, 170)),
      enemyA: spriteFromRect(const Rect.fromLTWH(715, 320, 220, 185)),
      enemyB: spriteFromRect(const Rect.fromLTWH(935, 320, 240, 190)),
      enemyC: spriteFromRect(const Rect.fromLTWH(1160, 325, 240, 190)),
      playerBullet: spriteFromRect(const Rect.fromLTWH(505, 525, 145, 235)),
      enemyBullet: spriteFromRect(const Rect.fromLTWH(965, 525, 145, 235)),
      explosion: spriteFromRect(const Rect.fromLTWH(1170, 520, 250, 235)),
    );
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
    setState(() {
      playerX = 0;
      enemies = [];
      playerBullets = [];
      enemyBullets = [];
      bursts = [];
      score = 0;
      isGameOver = false;
      isStarted = true;
      _configureWave(1);
    });
    gameTimer?.cancel();
    _stopMoveRepeat();
    _stopShootRepeat();
    gameTimer = async.Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) => _tick(),
    );
  }

  void _configureWave(int nextWave) {
    wave = nextWave;
    enemiesRemainingToSpawn = _enemyBudgetForWave(nextWave);
    spawnCooldownMs = 120;
    enemyBullets = [];
  }

  int _enemyBudgetForWave(int currentWave) => 3 + currentWave * 2;

  int _maxEnemiesOnScreenForWave(int currentWave) => min(2 + currentWave, 8);

  double _spawnIntervalForWave(int currentWave) =>
      max(950 - currentWave * 70, 260).toDouble();

  double _enemyVerticalSpeedForWave(int currentWave) =>
      min(0.45 + currentWave * 0.06, 1.45);

  double _enemyHorizontalSpeedForWave(int currentWave) =>
      min(0.7 + currentWave * 0.05, 1.7);

  double _enemyFireChanceForWave(int currentWave, int activeEnemies) {
    return min(0.0018 + currentWave * 0.00035 + activeEnemies * 0.0002, 0.018);
  }

  void _tick() {
    if (!isStarted || isGameOver) return;

    final updatedEnemies = enemies.map((enemy) => enemy.copy()).toList();
    final updatedPlayerBullets = playerBullets
        .map((bullet) => bullet.copy())
        .toList();
    final updatedEnemyBullets = enemyBullets
        .map((bullet) => bullet.copy())
        .toList();
    final updatedBursts = bursts.map((burst) => burst.copy()).toList();
    var nextSpawnCooldownMs = max(spawnCooldownMs - tickMs, 0.0).toDouble();
    var nextEnemiesRemaining = enemiesRemainingToSpawn;
    var nextScore = score;
    var shouldLose = false;

    for (final bullet in updatedPlayerBullets) {
      bullet.y -= playerBulletSpeed;
    }
    updatedPlayerBullets.removeWhere((bullet) => bullet.y < -bulletHeight);

    for (final bullet in updatedEnemyBullets) {
      bullet.y += enemyBulletSpeed;
    }
    updatedEnemyBullets.removeWhere(
      (bullet) => bullet.y > screenHeight + bulletHeight,
    );

    for (final enemy in updatedEnemies) {
      enemy.x += enemy.dx;
      enemy.y += enemy.speedY;

      if (enemy.x <= 12 || enemy.x >= screenWidth - enemy.size - 12) {
        enemy.dx = -enemy.dx;
        enemy.x = enemy.x.clamp(12, screenWidth - enemy.size - 12).toDouble();
      }
    }

    if (nextEnemiesRemaining > 0 &&
        updatedEnemies.length < _maxEnemiesOnScreenForWave(wave) &&
        nextSpawnCooldownMs <= 0) {
      updatedEnemies.add(_spawnEnemy(updatedEnemies));
      nextEnemiesRemaining--;
      nextSpawnCooldownMs = _spawnIntervalForWave(wave);
    }

    if (updatedEnemies.isNotEmpty &&
        _random.nextDouble() <
            _enemyFireChanceForWave(wave, updatedEnemies.length)) {
      final shooter = updatedEnemies[_random.nextInt(updatedEnemies.length)];
      updatedEnemyBullets.add(
        Bullet(
          shooter.x + shooter.size / 2,
          shooter.y + shooter.size + 8,
          false,
        ),
      );
    }

    for (final bullet in updatedPlayerBullets) {
      if (bullet.hit) continue;
      for (final enemy in updatedEnemies) {
        if (enemy.hit) continue;
        final enemyRect = Rect.fromLTWH(
          enemy.x,
          enemy.y,
          enemy.size,
          enemy.size,
        );
        final bulletRect = Rect.fromCenter(
          center: Offset(bullet.x, bullet.y),
          width: bulletWidth,
          height: bulletHeight,
        );
        if (bulletRect.overlaps(enemyRect)) {
          bullet.hit = true;
          enemy.hit = true;
          nextScore += 10 + wave * 2;
          updatedBursts.add(
            ExplosionBurst(
              x: enemy.x + enemy.size / 2,
              y: enemy.y + enemy.size / 2,
              size: enemy.size + 40,
              ttlMs: 70,
            ),
          );
          break;
        }
      }
    }

    updatedPlayerBullets.removeWhere((bullet) => bullet.hit);
    updatedEnemies.removeWhere((enemy) => enemy.hit);

    for (final burst in updatedBursts) {
      burst.ttlMs -= tickMs;
    }
    updatedBursts.removeWhere((burst) => burst.ttlMs <= 0);

    final playerRect = Rect.fromLTWH(
      (screenWidth - playerWidth) / 2 + playerX,
      _playerTop(),
      playerWidth,
      playerHeight,
    );

    for (final bullet in updatedEnemyBullets) {
      final bulletRect = Rect.fromCenter(
        center: Offset(bullet.x, bullet.y),
        width: bulletWidth,
        height: bulletHeight,
      );
      if (bulletRect.overlaps(playerRect)) {
        shouldLose = true;
        break;
      }
    }

    if (!shouldLose) {
      for (final enemy in updatedEnemies) {
        if (enemy.y + enemy.size >= _playerTop() + playerHeight * 0.6) {
          shouldLose = true;
          break;
        }
      }
    }

    final shouldAdvanceWave =
        !shouldLose && nextEnemiesRemaining == 0 && updatedEnemies.isEmpty;

    setState(() {
      enemies = updatedEnemies;
      playerBullets = updatedPlayerBullets;
      enemyBullets = updatedEnemyBullets;
      bursts = updatedBursts;
      enemiesRemainingToSpawn = nextEnemiesRemaining;
      spawnCooldownMs = nextSpawnCooldownMs;
      score = nextScore;
      if (nextScore > highScore) {
        highScore = nextScore;
      }
    });

    if (shouldLose) {
      _endGame();
    } else if (shouldAdvanceWave) {
      _startNextWave();
    }
  }

  EnemyShip _spawnEnemy(List<EnemyShip> activeEnemies) {
    final size = (_random.nextDouble() * 10) + 28;
    final direction = _random.nextBool() ? 1.0 : -1.0;
    final dx = direction * _enemyHorizontalSpeedForWave(wave);
    final speedY = _enemyVerticalSpeedForWave(wave);
    var x = _random.nextDouble() * (screenWidth - size - 24) + 12;

    for (int attempt = 0; attempt < 6; attempt++) {
      final overlaps = activeEnemies.any(
        (enemy) => (enemy.x - x).abs() < max(enemy.size, size) * 1.15,
      );
      if (!overlaps) break;
      x = _random.nextDouble() * (screenWidth - size - 24) + 12;
    }

    return EnemyShip(
      x: x,
      y: -size - (_random.nextDouble() * 80),
      dx: dx,
      speedY: speedY,
      size: size,
      variant: _random.nextInt(3),
    );
  }

  void _startNextWave() {
    setState(() {
      _configureWave(wave + 1);
    });
  }

  void _endGame() {
    final shouldPersistHighScore = score >= highScore && highScore > 0;
    setState(() {
      isGameOver = true;
      isStarted = false;
    });
    gameTimer?.cancel();
    _stopMoveRepeat();
    _stopShootRepeat();
    if (shouldPersistHighScore) {
      _saveHighScore();
    }
  }

  void _movePlayer(int dir) {
    if (!isStarted || isGameOver) return;
    setState(() {
      playerX += dir * moveStep;
      playerX = playerX
          .clamp(
            -(screenWidth - playerWidth) / 2,
            (screenWidth - playerWidth) / 2,
          )
          .toDouble();
    });
  }

  void _shoot() {
    if (!isStarted || isGameOver) return;
    final shipCenterX = screenWidth / 2 + playerX;
    final bulletStartY = _playerTop() - bulletHeight / 2;
    setState(() {
      playerBullets.add(Bullet(shipCenterX, bulletStartY, true));
    });
  }

  void _startMoveRepeat(int dir) {
    if (!isStarted || isGameOver) return;
    _movePlayer(dir);
    _moveRepeatTimer?.cancel();
    _moveRepeatTimer = async.Timer.periodic(
      const Duration(milliseconds: moveRepeatMs),
      (_) => _movePlayer(dir),
    );
  }

  void _stopMoveRepeat() {
    _moveRepeatTimer?.cancel();
    _moveRepeatTimer = null;
  }

  void _startShootRepeat() {
    if (!isStarted || isGameOver) return;
    _shoot();
    _shootRepeatTimer?.cancel();
    _shootRepeatTimer = async.Timer.periodic(
      const Duration(milliseconds: shootRepeatMs),
      (_) => _shoot(),
    );
  }

  void _stopShootRepeat() {
    _shootRepeatTimer?.cancel();
    _shootRepeatTimer = null;
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _stopMoveRepeat();
    _stopShootRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF39FF14);
    final neonBlue = const Color(0xFF00FFF7);
    final neonPink = const Color(0xFFFF00FF);
    final neonRed = const Color(0xFFFF073A);
    final neonYellow = const Color(0xFFFFFF00);

    return FutureBuilder<_SpriteAtlas>(
      future: _atlasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF18122B),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF18122B),
            body: Center(
              child: Text(
                'Failed to load Space War sprites',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final atlas = snapshot.data!;

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
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: _appBarHighScore(neonPink),
                    ),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  ...enemies.map((enemy) => _buildEnemy(enemy, atlas)),
                  ...playerBullets.map((bullet) => _buildBullet(bullet, atlas)),
                  ...enemyBullets.map((bullet) => _buildBullet(bullet, atlas)),
                  ...bursts.map((burst) => _buildBurst(burst, atlas)),
                  Positioned(
                    left: (screenWidth - playerWidth) / 2 + playerX,
                    top: _playerTop(),
                    bottom: 100,
                    child: _buildPlayer(atlas),
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _buildHud(neonBlue, neonYellow),
                  ),
                  if (isStarted && !isGameOver)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.42),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: neonBlue, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.18),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _controlButton(
                                    Icons.arrow_left,
                                    neonBlue,
                                    onPressStart: () => _startMoveRepeat(-1),
                                    onPressEnd: _stopMoveRepeat,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _controlButton(
                                    Icons.bolt,
                                    neonGreen,
                                    onPressStart: _startShootRepeat,
                                    onPressEnd: _stopShootRepeat,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _controlButton(
                                    Icons.arrow_right,
                                    neonPink,
                                    onPressStart: () => _startMoveRepeat(1),
                                    onPressEnd: _stopMoveRepeat,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!isStarted || isGameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.74),
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
                            const SizedBox(height: 12),
                            Text(
                              isGameOver
                                  ? 'Reached wave $wave with score $score'
                                  : 'Sprite-powered dogfight online.',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Orbitron',
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'High Score: $highScore',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Orbitron',
                                color: neonPink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
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
      },
    );
  }

  Widget _statCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Orbitron',
          color: color,
          fontWeight: FontWeight.bold,
          // letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _appBarHighScore(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        'High $highScore',
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'Orbitron',
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHud(Color neonBlue, Color neonYellow) {
    final statusText = enemiesRemainingToSpawn > 0
        ? 'Incoming: ${enemiesRemainingToSpawn + enemies.length}'
        : 'Clear the sky';

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _statCard('Wave ${max(wave, 1)}', neonBlue),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _statCard('Score $score', neonYellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontFamily: 'Orbitron',
                color: Colors.white.withOpacity(0.82),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemy(EnemyShip enemy, _SpriteAtlas atlas) {
    final spriteSize = enemy.size + 36;
    return Positioned(
      left: enemy.x - (spriteSize - enemy.size) / 2,
      top: enemy.y - (spriteSize - enemy.size) / 2,
      child: _spriteBox(
        sprite: atlas.enemyFor(enemy.variant),
        width: spriteSize,
        height: spriteSize,
      ),
    );
  }

  Widget _buildPlayer(_SpriteAtlas atlas) {
    const spriteWidth = 110.0;
    const spriteHeight = 110.0;
    return Transform.translate(
      offset: const Offset(-(spriteWidth - playerWidth) / 2, -26),
      child: _spriteBox(
        sprite: atlas.playerIdle,
        width: spriteWidth,
        height: spriteHeight,
      ),
    );
  }

  Widget _buildBullet(Bullet bullet, _SpriteAtlas atlas) {
    final spriteWidth = bullet.fromPlayer ? 16.0 : 16.0;
    final spriteHeight = bullet.fromPlayer ? 44.0 : 36.0;
    return Positioned(
      left: bullet.x - spriteWidth / 2,
      top: bullet.y - spriteHeight / 2,
      child: _spriteBox(
        sprite: bullet.fromPlayer ? atlas.playerBullet : atlas.enemyBullet,
        width: spriteWidth,
        height: spriteHeight,
      ),
    );
  }

  Widget _buildBurst(ExplosionBurst burst, _SpriteAtlas atlas) {
    return Positioned(
      left: burst.x - burst.size / 2,
      top: burst.y - burst.size / 2,
      child: Opacity(
        opacity: (burst.ttlMs / 70).clamp(0.0, 1.0).toDouble(),
        child: _spriteBox(
          sprite: atlas.explosion,
          width: burst.size,
          height: burst.size,
        ),
      ),
    );
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

  Widget _controlButton(
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
    VoidCallback? onPressStart,
    VoidCallback? onPressEnd,
  }) {
    return ArcadeIconButton(
      icon: icon,
      color: color,
      size: 72,
      hitSize: 88,
      iconSize: 30,
      onPressed: onPressed,
      onPressStart: onPressStart,
      onPressEnd: onPressEnd,
    );
  }

  Widget _neonButton(String text, VoidCallback onPressed, Color color) {
    return ArcadeButton(label: text, color: color, onPressed: onPressed);
  }

  double _playerTop() => screenHeight - controlPanelHeight - playerHeight - 28;
}

class EnemyShip {
  EnemyShip({
    required this.x,
    required this.y,
    required this.dx,
    required this.speedY,
    required this.size,
    required this.variant,
    this.hit = false,
  });

  double x;
  double y;
  double dx;
  double speedY;
  double size;
  int variant;
  bool hit;

  EnemyShip copy() => EnemyShip(
    x: x,
    y: y,
    dx: dx,
    speedY: speedY,
    size: size,
    variant: variant,
    hit: hit,
  );
}

class Bullet {
  Bullet(this.x, this.y, this.fromPlayer, {this.hit = false});

  double x;
  double y;
  bool fromPlayer;
  bool hit;

  Bullet copy() => Bullet(x, y, fromPlayer, hit: hit);
}

class ExplosionBurst {
  ExplosionBurst({
    required this.x,
    required this.y,
    required this.size,
    required this.ttlMs,
  });

  double x;
  double y;
  double size;
  double ttlMs;

  ExplosionBurst copy() => ExplosionBurst(x: x, y: y, size: size, ttlMs: ttlMs);
}

class _SpriteAtlas {
  const _SpriteAtlas({
    required this.playerIdle,
    required this.enemyA,
    required this.enemyB,
    required this.enemyC,
    required this.playerBullet,
    required this.enemyBullet,
    required this.explosion,
  });

  final Sprite playerIdle;
  final Sprite enemyA;
  final Sprite enemyB;
  final Sprite enemyC;
  final Sprite playerBullet;
  final Sprite enemyBullet;
  final Sprite explosion;

  Sprite enemyFor(int variant) {
    switch (variant % 3) {
      case 0:
        return enemyA;
      case 1:
        return enemyB;
      default:
        return enemyC;
    }
  }
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
