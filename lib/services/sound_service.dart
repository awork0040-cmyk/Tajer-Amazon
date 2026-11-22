import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _scanPlayer = AudioPlayer();
  final AudioPlayer _transitionPlayer = AudioPlayer();

  bool _enabled = true;
  bool _vibrationEnabled = true;

  void setEnabled(bool value) => _enabled = value;
  void setVibrationEnabled(bool value) => _vibrationEnabled = value;
  bool get enabled => _enabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> _play(AudioPlayer player, String asset) async {
    if (!_enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> playTap() async {
    // معطّل حالياً
  }

  Future<void> playSuccess() async {
    await _play(_successPlayer, 'audio/success.mp3');
  }

  Future<void> playError() async {
    await _play(_errorPlayer, 'audio/error.mp3');
  }

  Future<void> playScan() async {
    await _play(_scanPlayer, 'audio/scan.mp3');
  }

  Future<void> playTransition() async {
    await _play(_transitionPlayer, 'audio/transition.mp3');
  }

  Future<void> vibrateLight() async {
    if (!_vibrationEnabled) return;
    if (kIsWeb) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
      return;
    }
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 50);
      }
    } catch (_) {}
  }

  Future<void> vibrateMedium() async {
    if (!_vibrationEnabled) return;
    if (kIsWeb) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
      return;
    }
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 150);
      }
    } catch (_) {}
  }

  Future<void> vibrateStrong() async {
    if (!_vibrationEnabled) return;
    if (kIsWeb) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
      return;
    }
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 100, 50, 100]);
      }
    } catch (_) {}
  }

  void dispose() {
    _successPlayer.dispose();
    _errorPlayer.dispose();
    _scanPlayer.dispose();
    _transitionPlayer.dispose();
  }
}