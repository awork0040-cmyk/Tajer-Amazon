import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  bool _scanSound = true;
  bool _scanVibration = true;
  bool _errorVibration = true;
  bool _buttonSound = true;
  bool _keepScreenOn = false;
  double _volumeLevel = 0.7;
  double _vibrationLevel = 0.5;

  bool _initialized = false;
  File? _settingsFile;

  bool get scanSound => _scanSound;
  bool get scanVibration => _scanVibration;
  bool get errorVibration => _errorVibration;
  bool get buttonSound => _buttonSound;
  bool get keepScreenOn => _keepScreenOn;
  double get volumeLevel => _volumeLevel;
  double get vibrationLevel => _vibrationLevel;

  int getVibrationDurationMs() {
    if (_vibrationLevel <= 0.33) return 50;
    if (_vibrationLevel <= 0.66) return 150;
    return 300;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _settingsFile = File(p.join(appDir.path, 'settings.json'));
      await _load();
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final file = _settingsFile;
      if (file == null || !await file.exists()) return;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _scanSound = (json['scanSound'] as bool?) ?? true;
      _scanVibration = (json['scanVibration'] as bool?) ?? true;
      _errorVibration = (json['errorVibration'] as bool?) ?? true;
      _buttonSound = (json['buttonSound'] as bool?) ?? true;
      _keepScreenOn = (json['keepScreenOn'] as bool?) ?? false;
      _volumeLevel = (json['volumeLevel'] as num?)?.toDouble() ?? 0.7;
      _vibrationLevel = (json['vibrationLevel'] as num?)?.toDouble() ?? 0.5;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final file = _settingsFile;
      if (file == null) return;
      final json = <String, dynamic>{
        'scanSound': _scanSound,
        'scanVibration': _scanVibration,
        'errorVibration': _errorVibration,
        'buttonSound': _buttonSound,
        'keepScreenOn': _keepScreenOn,
        'volumeLevel': _volumeLevel,
        'vibrationLevel': _vibrationLevel,
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );
    } catch (_) {}
  }

  void setScanSound(bool v) {
    _scanSound = v;
    _save();
    notifyListeners();
  }

  void setScanVibration(bool v) {
    _scanVibration = v;
    _save();
    notifyListeners();
  }

  void setErrorVibration(bool v) {
    _errorVibration = v;
    _save();
    notifyListeners();
  }

  void setButtonSound(bool v) {
    _buttonSound = v;
    _save();
    notifyListeners();
  }

  void setKeepScreenOn(bool v) {
    _keepScreenOn = v;
    _save();
    notifyListeners();
  }

  void setVolumeLevel(double v) {
    _volumeLevel = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  void setVibrationLevel(double v) {
    _vibrationLevel = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  void resetAll() {
    _scanSound = true;
    _scanVibration = true;
    _errorVibration = true;
    _buttonSound = true;
    _keepScreenOn = false;
    _volumeLevel = 0.7;
    _vibrationLevel = 0.5;
    _save();
    notifyListeners();
  }
}