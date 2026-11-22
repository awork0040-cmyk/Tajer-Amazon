import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  // ═══════════════════════════════════════════════════════════
  // الحقول
  // ═══════════════════════════════════════════════════════════

  bool _scanSound = true;
  bool _scanVibration = true;
  bool _errorVibration = true;
  int _frameColorOption = 0;
  bool _buttonSound = true;
  bool _keepScreenOn = false;
  double _volumeLevel = 0.7;
  double _vibrationLevel = 0.5;

  bool _initialized = false;
  File? _settingsFile;

  // ═══════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════

  bool get scanSound => _scanSound;
  bool get scanVibration => _scanVibration;
  bool get errorVibration => _errorVibration;
  int get frameColorOption => _frameColorOption;
  bool get buttonSound => _buttonSound;
  bool get keepScreenOn => _keepScreenOn;
  double get volumeLevel => _volumeLevel;
  double get vibrationLevel => _vibrationLevel;

  // ═══════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════

  /// يرجع لون إطار المسح حسب الإعداد المختار.
  Color getFrameColor() {
    switch (_frameColorOption) {
      case 1:
        return const Color(0xFF3FB950); // أخضر
      case 2:
        return const Color(0xFF2AABEE); // أزرق
      case 3:
        return const Color(0xFFE53935); // أحمر
      default:
        return Colors.white;
    }
  }

  /// يرجع مدة الاهتزاز بالمللي ثانية حسب مستوى الاهتزاز.
  int getVibrationDurationMs() {
    if (_vibrationLevel <= 0.33) return 50;
    if (_vibrationLevel <= 0.66) return 150;
    return 300;
  }

  // ═══════════════════════════════════════════════════════════
  // Initialize
  // ═══════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _settingsFile = File(p.join(appDir.path, 'settings.json'));
      await _load();
    } catch (_) {
      // استخدام الافتراضيات
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Load / Save
  // ═══════════════════════════════════════════════════════════

  Future<void> _load() async {
    try {
      final file = _settingsFile;
      if (file == null || !await file.exists()) return;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      _scanSound = (json['scanSound'] as bool?) ?? true;
      _scanVibration = (json['scanVibration'] as bool?) ?? true;
      _errorVibration = (json['errorVibration'] as bool?) ?? true;
      _frameColorOption = (json['frameColorOption'] as int?) ?? 0;
      _buttonSound = (json['buttonSound'] as bool?) ?? true;
      _keepScreenOn = (json['keepScreenOn'] as bool?) ?? false;
      _volumeLevel = (json['volumeLevel'] as num?)?.toDouble() ?? 0.7;
      _vibrationLevel = (json['vibrationLevel'] as num?)?.toDouble() ?? 0.5;

      notifyListeners();
    } catch (_) {
      // استخدام الافتراضيات
    }
  }

  Future<void> _save() async {
    try {
      final file = _settingsFile;
      if (file == null) return;

      final json = <String, dynamic>{
        'scanSound': _scanSound,
        'scanVibration': _scanVibration,
        'errorVibration': _errorVibration,
        'frameColorOption': _frameColorOption,
        'buttonSound': _buttonSound,
        'keepScreenOn': _keepScreenOn,
        'volumeLevel': _volumeLevel,
        'vibrationLevel': _vibrationLevel,
      };

      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    } catch (_) {
      // تجاهل أخطاء الحفظ
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Setters
  // ═══════════════════════════════════════════════════════════

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

  void setFrameColorOption(int v) {
    if (v < 0 || v > 3) return;
    _frameColorOption = v;
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

  // ═══════════════════════════════════════════════════════════
  // Reset
  // ═══════════════════════════════════════════════════════════

  void resetAll() {
    _scanSound = true;
    _scanVibration = true;
    _errorVibration = true;
    _frameColorOption = 0;
    _buttonSound = true;
    _keepScreenOn = false;
    _volumeLevel = 0.7;
    _vibrationLevel = 0.5;
    _save();
    notifyListeners();
  }
}