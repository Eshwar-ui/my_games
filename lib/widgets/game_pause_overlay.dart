import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_arcade_button.dart';

class GamePauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  final Color accentColor;

  const GamePauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    this.accentColor = const Color(0xFF00FFF7),
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 48,
                  fontFamily: 'Orbitron',
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: accentColor.withOpacity(0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              _PauseButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                color: accentColor,
                onPressed: onResume,
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              _PauseButton(
                label: 'RESTART',
                icon: Icons.refresh_rounded,
                color: Colors.white70,
                onPressed: onRestart,
              ),
              const SizedBox(height: 16),
              _PauseButton(
                label: 'QUIT',
                icon: Icons.exit_to_app_rounded,
                color: const Color(0xFFFF073A),
                onPressed: onQuit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _PauseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 54,
      child: ArcadeButton(
        label: label,
        color: color,
        onPressed: onPressed,
      ),
    );
  }
}
