import 'package:flutter/material.dart';

import 'game_haptics.dart';

class ArcadeButton extends StatelessWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.minWidth = 220,
    this.minHeight = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                GameHaptics.tap();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF24193D),
          foregroundColor: color,
          disabledBackgroundColor: const Color(0xFF1A1330),
          disabledForegroundColor: color.withOpacity(0.45),
          elevation: 10,
          shadowColor: color.withOpacity(0.55),
          padding: padding,
          tapTargetSize: MaterialTapTargetSize.padded,
          minimumSize: Size(minWidth, minHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: color, width: 3),
          ),
          textStyle: const TextStyle(
            fontSize: 22,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            shadows: [Shadow(color: color.withOpacity(0.45), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class ArcadeIconButton extends StatefulWidget {
  const ArcadeIconButton({
    super.key,
    required this.icon,
    required this.color,
    this.onPressed,
    this.onPressStart,
    this.onPressEnd,
    this.size = 72,
    this.iconSize = 36,
    this.hitSize = 96,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;
  final double size;
  final double iconSize;
  final double hitSize;

  @override
  State<ArcadeIconButton> createState() => _ArcadeIconButtonState();
}

class _ArcadeIconButtonState extends State<ArcadeIconButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.hitSize,
      height: widget.hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _setPressed(true);
          GameHaptics.tap();
          widget.onPressStart?.call();
        },
        onTapUp: (_) {
          _setPressed(false);
          widget.onPressEnd?.call();
        },
        onTapCancel: () {
          _setPressed(false);
          widget.onPressEnd?.call();
        },
        onTap: widget.onPressStart == null
            ? () {
                GameHaptics.tap();
                widget.onPressed?.call();
              }
            : null,
        child: Center(
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isPressed
                    ? const Color(0xFF1C1333)
                    : const Color(0xFF24193D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: widget.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_isPressed ? 0.22 : 0.5),
                    blurRadius: _isPressed ? 8 : 16,
                    spreadRadius: _isPressed ? 0 : 1,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
