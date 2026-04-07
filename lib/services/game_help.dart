import 'package:flutter/material.dart';

class GameHelpAction extends StatelessWidget {
  const GameHelpAction({
    super.key,
    required this.title,
    required this.accent,
    required this.steps,
    this.tip,
  });

  final String title;
  final Color accent;
  final List<String> steps;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'How to play',
      onPressed: () => showGameHelp(context, title, accent, steps, tip: tip),
    );
  }
}

Future<void> showGameHelp(
  BuildContext context,
  String title,
  Color accent,
  List<String> steps, {
  String? tip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161122),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.45)),
                    ),
                    child: Icon(Icons.videogame_asset, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$title Help',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...List.generate(steps.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (tip != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    'Tip: $tip',
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
