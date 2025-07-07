import 'package:flutter/material.dart';
import 'dart:math';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame>
    with TickerProviderStateMixin {
  static const int gridSize = 3;
  List<List<String?>> _board = List.generate(
    gridSize,
    (_) => List.filled(gridSize, null),
  );
  String _currentPlayer = 'X';
  String? _winner;
  bool _isDraw = false;
  List<List<bool>> _winningCells = List.generate(
    gridSize,
    (_) => List.filled(gridSize, false),
  );

  late AnimationController _billboardController;
  late Animation<Offset> _billboardOffset;

  @override
  void initState() {
    super.initState();
    debugPrint('TicTacToeGameState: initState, using TickerProviderStateMixin');
    _billboardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _billboardOffset =
        Tween<Offset>(
          begin: const Offset(0, -1.2),
          end: const Offset(0, 0.1),
        ).animate(
          CurvedAnimation(
            parent: _billboardController,
            curve: Curves.elasticOut,
          ),
        );
  }

  @override
  void dispose() {
    debugPrint('TicTacToeGameState: dispose called');
    _billboardController.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(gridSize, (_) => List.filled(gridSize, null));
      _currentPlayer = 'X';
      _winner = null;
      _isDraw = false;
      _winningCells = List.generate(
        gridSize,
        (_) => List.filled(gridSize, false),
      );
    });
    _billboardController.reset();
  }

  void _handleTap(int row, int col) {
    if (_board[row][col] != null || _winner != null) return;
    setState(() {
      _board[row][col] = _currentPlayer;
      if (_checkWinnerAndMark(row, col)) {
        _winner = _currentPlayer;
        _billboardController.forward(from: 0);
      } else if (_isBoardFull()) {
        _isDraw = true;
      } else {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
      }
    });
  }

  bool _isBoardFull() {
    for (var row in _board) {
      for (var cell in row) {
        if (cell == null) return false;
      }
    }
    return true;
  }

  bool _checkWinnerAndMark(int lastRow, int lastCol) {
    String? player = _board[lastRow][lastCol];
    // Check row
    if (_board[lastRow].every((cell) => cell == player)) {
      for (int c = 0; c < gridSize; c++) {
        _winningCells[lastRow][c] = true;
      }
      return true;
    }
    // Check column
    if (_board.every((row) => row[lastCol] == player)) {
      for (int r = 0; r < gridSize; r++) {
        _winningCells[r][lastCol] = true;
      }
      return true;
    }
    // Check diagonal
    if (lastRow == lastCol &&
        List.generate(
          gridSize,
          (i) => _board[i][i],
        ).every((cell) => cell == player)) {
      for (int i = 0; i < gridSize; i++) {
        _winningCells[i][i] = true;
      }
      return true;
    }
    // Check anti-diagonal
    if (lastRow + lastCol == gridSize - 1 &&
        List.generate(
          gridSize,
          (i) => _board[i][gridSize - 1 - i],
        ).every((cell) => cell == player)) {
      for (int i = 0; i < gridSize; i++) {
        _winningCells[i][gridSize - 1 - i] = true;
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final neonBlue = const Color(0xFF00FFF7);
    final neonPink = const Color(0xFFFF00FF);
    final neonGreen = const Color(0xFF39FF14);
    final neonYellow = const Color(0xFFFFFF00);
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tic-Tac-Toe',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color(0xFF00FFF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: neonGreen),
            onPressed: _resetGame,
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Billboard animation at the top (always on top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _billboardController,
                builder: (context, child) {
                  if (_winner == null) return const SizedBox.shrink();
                  return SlideTransition(
                    position: _billboardOffset,
                    child: _buildBillboard(_winner!),
                  );
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isDraw)
                  Text(
                    'It\'s a Draw!',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      color: neonYellow,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: neonYellow.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  )
                else if (_winner == null)
                  Text(
                    'Player $_currentPlayer\'s turn',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'Orbitron',
                      color: neonBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: neonBlue.withOpacity(0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                _buildBoard(neonBlue, neonPink),
                const SizedBox(height: 32),
                _neonButton('Restart', _resetGame, neonGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(Color neonBlue, Color neonPink) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonPink, width: 3),
        color: Colors.white.withOpacity(0.04),
        boxShadow: [
          BoxShadow(
            color: neonPink.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(gridSize, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(gridSize, (col) {
              return _buildCell(row, col, neonBlue, neonPink);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col, Color neonBlue, Color neonPink) {
    final value = _board[row][col];
    final isWinning = _winningCells[row][col];
    final isWinner = _winner == value;
    final isLoser = _winner != null && value != null && value != _winner;
    Color color = value == 'X'
        ? neonBlue
        : (value == 'O' ? neonPink : Colors.white.withOpacity(0.05));
    double opacity = 1.0;
    if (_winner != null) {
      if (isWinning) {
        opacity = 1.0;
      } else if (isLoser) {
        opacity = 0.25;
        color = color.withOpacity(0.25);
      } else {
        opacity = 0.5;
      }
    }
    return GestureDetector(
      onTap: () => _handleTap(row, col),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 80,
          height: 80,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.03),
            boxShadow: value != null && opacity > 0.5
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              value ?? '',
              style: TextStyle(
                fontSize: 48,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: color.withOpacity(0.7), blurRadius: 12),
                ],
              ),
            ),
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

  Widget _buildBillboard(String winner) {
    final neonGreen = const Color(0xFF39FF14);
    final neonBlue = const Color(0xFF00FFF7);
    final neonPink = const Color(0xFFFF00FF);
    final color = winner == 'X' ? neonBlue : neonPink;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: neonGreen, size: 48),
            const SizedBox(height: 8),
            Text(
              'Player $winner Wins!',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Orbitron',
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: color.withOpacity(0.7), blurRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
