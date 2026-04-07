import 'dart:math';

import 'package:flutter/material.dart';

import '../services/arcade_stats_service.dart';
import '../services/game_haptics.dart';
import '../services/game_help.dart';
import '../services/haptic_arcade_button.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  final List<_MemoryCard> _cards = [];
  final List<int> _flipped = [];
  bool _locked = false;
  int _moves = 0;
  int _matches = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    GameHaptics.preload();
    _startGame();
  }

  void _startGame() {
    const symbols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final items = [...symbols, ...symbols]..shuffle(Random());
    _cards
      ..clear()
      ..addAll(items.map((symbol) => _MemoryCard(symbol: symbol)));
    _flipped.clear();
    _locked = false;
    _moves = 0;
    _matches = 0;
    _won = false;
    ArcadeStatsService.recordPlay('memory_match');
    setState(() {});
  }

  Future<void> _handleTap(int index) async {
    if (_locked || _won || _cards[index].matched || _cards[index].revealed) {
      return;
    }

    setState(() {
      _cards[index].revealed = true;
      _flipped.add(index);
    });
    GameHaptics.tap();

    if (_flipped.length < 2) return;

    setState(() {
      _moves += 1;
      _locked = true;
    });

    final first = _cards[_flipped[0]];
    final second = _cards[_flipped[1]];
    if (first.symbol == second.symbol) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      setState(() {
        first.matched = true;
        second.matched = true;
        _matches += 1;
        _flipped.clear();
        _locked = false;
        _won = _matches == 8;
      });
      GameHaptics.medium();
      if (_won) {
        GameHaptics.heavy();
        ArcadeStatsService.recordResult(
          'memory_match',
          score: max(0, 100 - (_moves * 4)),
          won: true,
        );
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      setState(() {
        first.revealed = false;
        second.revealed = false;
        _flipped.clear();
        _locked = false;
      });
      GameHaptics.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6B6B);
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Memory Match',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const GameHelpAction(
            title: 'Memory Match',
            accent: accent,
            steps: [
              'Tap two cards to reveal them.',
              'Matching symbols stay open and count as a pair.',
              'Clear all 8 pairs in as few moves as possible.',
            ],
            tip: 'Open corners and edges early to build a reliable memory map.',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF39FF14)),
            onPressed: _startGame,
            tooltip: 'Restart',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _statCard('Moves', '$_moves', accent)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Pairs',
                      '$_matches / 8',
                      const Color(0xFF00FFF7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final revealed = card.revealed || card.matched;
                    return GestureDetector(
                      onTap: () => _handleTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: revealed
                              ? accent.withOpacity(card.matched ? 0.2 : 0.14)
                              : const Color(0xFF24193D),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: revealed ? accent : Colors.white24,
                            width: 2,
                          ),
                          boxShadow: revealed
                              ? [
                                  BoxShadow(
                                    color: accent.withOpacity(0.25),
                                    blurRadius: 14,
                                  ),
                                ]
                              : const [],
                        ),
                        child: Center(
                          child: Text(
                            revealed ? card.symbol : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: revealed ? accent : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_won) ...[
                const SizedBox(height: 12),
                Text(
                  'Board cleared in $_moves moves',
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ArcadeButton(
                label: _won ? 'Play Again' : 'Restart',
                color: accent,
                onPressed: _startGame,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF24193D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard {
  _MemoryCard({
    required this.symbol,
    this.revealed = false,
    this.matched = false,
  });

  final String symbol;
  bool revealed;
  bool matched;
}
