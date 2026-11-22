import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _scanLineController;
  late final AnimationController _pulseController;

  bool _isProcessing = false;
  bool _torchOn = false;
  DateTime? _lastInvalidScan;

  Color _frameColor = Colors.white;
  double _pulseScale = 1.0;
  Timer? _colorResetTimer;

  static const String _notFoundMessage =
      'لا توجد عملية بهذا الرمز. قد يكون الملصق تالفاً أو لعملية محذوفة.';
  static const String _unreadableMessage =
      'تعذر قراءة الرمز. تأكد من وضوحه أو اقترب أكثر.';

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.unrestricted,
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseController.addListener(() {
      setState(() => _pulseScale = 1.0 + (_pulseController.value * 0.08));
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    _colorResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      final newState = _controller.value.torchState;
      final isOn = newState == TorchState.on;
      setState(() => _torchOn = isOn);
      if (!isOn) {
        _showInfoSnack('الفلاش غير متاح على هذه المنصة');
      }
    } catch (_) {
      if (mounted) _showInfoSnack('الفلاش غير متاح على هذه المنصة');
    }
  }

  void _showInfoSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showNotFoundSnack({String? overrideMessage}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(overrideMessage ?? _notFoundMessage),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _flashFrameColor(Color color) {
    _colorResetTimer?.cancel();
    setState(() => _frameColor = color);
    _pulseController.forward(from: 0).then((_) {
      _pulseController.reverse();
    });
    _colorResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _frameColor = Colors.white);
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;

    // رمز مكتشف لكن غير قابل للقراءة (تالف/مقصوص)
    if (value == null || value.isEmpty) {
      final now = DateTime.now();
      if (_lastInvalidScan != null &&
          now.difference(_lastInvalidScan!).inMilliseconds < 2000) {
        return;
      }
      _lastInvalidScan = now;
      _showNotFoundSnack(overrideMessage: _unreadableMessage);
      return;
    }

    final op = DataService.instance.getOperationBySerial(value);
    final isValid = op != null && op.status != OperationStatus.deleted;

    if (isValid) {
      _isProcessing = true;

      SoundService.instance.setEnabled(SettingsService.instance.scanSound);
      SoundService.instance
          .setVibrationEnabled(SettingsService.instance.scanVibration);

      if (SettingsService.instance.scanSound) {
        SoundService.instance.playScan();
      }
      if (SettingsService.instance.scanVibration) {
        SoundService.instance.vibrateMedium();
      }

      _flashFrameColor(const Color(0xFF3FB950));

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pop(context, value);
      return;
    }

    // QR صالح الشكل لكن لا يخص أي عملية
    final now = DateTime.now();
    if (_lastInvalidScan != null &&
        now.difference(_lastInvalidScan!).inMilliseconds < 2000) {
      return;
    }
    _lastInvalidScan = now;

    SoundService.instance.setEnabled(SettingsService.instance.scanSound);
    SoundService.instance
        .setVibrationEnabled(SettingsService.instance.errorVibration);

    if (SettingsService.instance.scanSound) {
      SoundService.instance.playError();
    }
    if (SettingsService.instance.errorVibration) {
      SoundService.instance.vibrateStrong();
    }

    _flashFrameColor(const Color(0xFFE53935));
    _showNotFoundSnack();
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: const Color(0xFF1C2733),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({
    required Alignment alignment,
    required BorderRadius radius,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? BorderSide(color: _frameColor, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: _frameColor, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? BorderSide(color: _frameColor, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: _frameColor, width: 4)
                : BorderSide.none,
          ),
          borderRadius: radius,
        ),
      ),
    );
  }

  Widget _buildScannerFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const boxSize = 260.0;
        final lineWidth = boxSize * 0.75;

        return Center(
          child: ScaleTransition(
            scale: AlwaysStoppedAnimation(_pulseScale),
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                children: [
                  _buildCorner(
                      alignment: Alignment.topLeft,
                      radius: const BorderRadius.only(
                          topLeft: Radius.circular(12))),
                  _buildCorner(
                      alignment: Alignment.topRight,
                      radius: const BorderRadius.only(
                          topRight: Radius.circular(12))),
                  _buildCorner(
                      alignment: Alignment.bottomLeft,
                      radius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12))),
                  _buildCorner(
                      alignment: Alignment.bottomRight,
                      radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12))),
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, _) {
                      final top =
                          20 + (_scanLineController.value * (boxSize - 40));
                      return Positioned(
                        top: top,
                        left: (boxSize - lineWidth) / 2,
                        child: Container(
                          width: lineWidth,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _frameColor.withOpacity(0.0),
                                _frameColor,
                                _frameColor,
                                _frameColor.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.2, 0.8, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _frameColor.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.5),
          BlendMode.srcOut,
        ),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 70,
          leadingWidth: 70,
          leading: Center(
            child: _buildFloatingButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          title: const Text(
            'مسح QR',
            style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildFloatingButton(
                icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                onTap: _toggleTorch,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذر فتح الكاميرا.\n${error.errorDetails?.message ?? error.errorCode.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            _buildOverlay(),
            _buildScannerFrame(),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'وجّه الكاميرا نحو رمز QR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
