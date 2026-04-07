import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameHaptics {
  static const String _vibrationEnabledKey = 'settings_vibration_enabled';

  static bool _enabled = true;

  static Future<void> preload() async {
    await _loadPreference();
  }

  static Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  static void tap() => _fire(HapticFeedback.selectionClick);

  static void light() => _fire(HapticFeedback.lightImpact);

  static void medium() => _fire(HapticFeedback.mediumImpact);

  static void heavy() => _fire(HapticFeedback.heavyImpact);

  static void _fire(Future<void> Function() feedback) {
    unawaited(_run(feedback));
  }

  static Future<void> _run(Future<void> Function() feedback) async {
    await _loadPreference();
    if (!_enabled) return;
    await feedback();
  }
}
