import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/arcade_button.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  static const String _audioEnabledKey = 'settings_audio_enabled';
  static const String _vibrationEnabledKey = 'settings_vibration_enabled';
  static const String _difficultyKey = 'settings_default_difficulty';
  static const Set<String> _resettableKeys = {
    'brick_breaker_high_score',
    'tetris_high_score',
    'snake_high_score',
    '2048_high_score',
    'space_war_high_score',
    'flappy_bird_high_score',
    _audioEnabledKey,
    _vibrationEnabledKey,
    _difficultyKey,
  };

  bool _isLoading = true;
  bool _audioEnabled = true;
  bool _vibrationEnabled = true;
  String _difficulty = 'Normal';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _audioEnabled = prefs.getBool(_audioEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      _difficulty = prefs.getString(_difficultyKey) ?? 'Normal';
      _isLoading = false;
    });
  }

  Future<void> _setAudioEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioEnabledKey, value);
    if (!mounted) return;

    setState(() {
      _audioEnabled = value;
    });
  }

  Future<void> _setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
    if (!mounted) return;

    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _setDifficulty(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_difficultyKey, value);
    if (!mounted) return;

    setState(() {
      _difficulty = value;
    });
  }

  Future<void> _resetLocalData() async {
    final shouldReset =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18122B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFFF073A), width: 2),
              ),
              title: const Text(
                'Reset Local Data?',
                style: TextStyle(
                  color: Color(0xFFFF073A),
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'This clears saved highscores and local settings on this device only.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF073A),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldReset) return;

    final prefs = await SharedPreferences.getInstance();
    for (final key in _resettableKeys) {
      await prefs.remove(key);
    }

    if (!mounted) return;

    setState(() {
      _audioEnabled = true;
      _vibrationEnabled = true;
      _difficulty = 'Normal';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local data cleared from this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00FFF7);
    const neonPink = Color(0xFFFF00FF);
    const neonGreen = Color(0xFF39FF14);
    const neonRed = Color(0xFFFF073A);
    const panelColor = Color(0xFF211537);

    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x2218FFF3),
                          Color(0x22FF00FF),
                          Color(0x2214FF72),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Controls',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: neonCyan,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Everything here stays on-device. No accounts, no sync, no cloud state.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsPanel(
                    title: 'Play Feel',
                    accent: neonCyan,
                    child: Column(
                      children: [
                        _SettingsSwitchTile(
                          title: 'Audio',
                          subtitle: 'Mute or enable bundled game audio.',
                          value: _audioEnabled,
                          accent: neonCyan,
                          onChanged: _setAudioEnabled,
                        ),
                        const SizedBox(height: 12),
                        _SettingsSwitchTile(
                          title: 'Vibration',
                          subtitle: 'Keep tap and gameplay feedback local.',
                          value: _vibrationEnabled,
                          accent: neonPink,
                          onChanged: _setVibrationEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsPanel(
                    title: 'Default Difficulty',
                    accent: neonGreen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: neonGreen.withOpacity(0.45),
                          width: 2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF24193D),
                          value: _difficulty,
                          isExpanded: true,
                          iconEnabledColor: neonGreen,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Orbitron',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Easy',
                              child: Text('Easy'),
                            ),
                            DropdownMenuItem(
                              value: 'Normal',
                              child: Text('Normal'),
                            ),
                            DropdownMenuItem(
                              value: 'Hard',
                              child: Text('Hard'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _setDifficulty(value);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsPanel(
                    title: 'Device Storage',
                    accent: neonRed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reset local data to clear highscores and saved preferences from this device.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        ArcadeButton(
                          label: 'Reset Local Data',
                          color: neonRed,
                          minWidth: double.infinity,
                          onPressed: _resetLocalData,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151022),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF24193D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
