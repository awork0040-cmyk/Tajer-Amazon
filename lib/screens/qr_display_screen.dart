import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';

enum _ScanState { idle, valid, deleted, unknown, invalid }

class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({Key? key}) : super(key: key);

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF3FB950);
  static const Color _orange = Color(0xFFF0883E);
  static const Color _gray = Color(0xFF8B949E);

  _ScanState _scanState = _ScanState.idle;
  Operation? _scannedOp;
  bool _flashOn = false;

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
      ],
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
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
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Color get _frameColor {
    switch (_scanState) {
      case _ScanState.valid:
        return _green;
      case _ScanState.deleted:
      case _ScanState.unknown:
        return _red;
      case _ScanState.invalid:
        return _orange;
      case _ScanState.idle:
        return Colors.white;
    }
  }

  void _lookupSerial(String rawSerial) {
    final serial = rawSerial.trim();
    if (serial.isEmpty) return;

    final ok = RegExp(r'^TA1-\d+$').hasMatch(serial);
    if (!ok) {
      setState(() {
        _scanState = _ScanState.invalid;
        _scannedOp = null;
      });
      return;
    }

    final op = DataService.instance.getOperationBySerial(serial);
    if (op == null) {
      setState(() {
        _scanState = _ScanState.unknown;
        _scannedOp = null;
      });
      return;
    }

    if (op.status == OperationStatus.deleted || op.deletedAt != null) {
      setState(() {
        _scanState = _ScanState.deleted;
        _scannedOp = op;
      });
      return;
    }

    setState(() {
      _scanState = _ScanState.valid;
      _scannedOp = op;
    });
  }

  Future<void> _showManualInput() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'إدخال رقم التسلسل',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Container(
          decoration: BoxDecoration(
            color: kScaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: controller,
            autofocus: true,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: kTextPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'TA1-1051',
              hintStyle: TextStyle(color: kTextSecondary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'بحث',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      _lookupSerial(result);
    }
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _showSnack('الكشاف غير متاح — الكاميرا وهمية', _orange);
  }

  String _displayCustomerName() {
    if (_scannedOp == null) return '';
    final current = DataService.instance.getCustomerById(_scannedOp!.customerId);
    return current?.primaryName ?? _scannedOp!.customerName;
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
            'عرض الملصق',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showManualInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withOpacity(0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.keyboard, color: kPrimary, size: 16),
                        SizedBox(width: 4),
                        Text('إدخال يدوي', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4, top: 12, bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _toggleFlash,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (_flashOn ? kPrimary : Colors.white).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_flashOn ? kPrimary : Colors.white).withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? kPrimary : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildCameraMock(),
            _buildScanFrame(),
            if (_scanState == _ScanState.idle) _buildIdleHint(),
            if (_scanState != _ScanState.idle) _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraMock() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0F15), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt,
          color: Colors.white.withOpacity(0.05),
          size: 180,
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    const double frameSize = 250;
    const double cornerLength = 28;
    const double cornerWidth = 3.5;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _frameColor.withOpacity(_scanState == _ScanState.idle ? 0.0 : 0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            _buildCorner(Alignment.topRight, cornerLength, cornerWidth, top: true, right: true),
            _buildCorner(Alignment.topLeft, cornerLength, cornerWidth, top: true, right: false),
            _buildCorner(Alignment.bottomRight, cornerLength, cornerWidth, top: false, right: true),
            _buildCorner(Alignment.bottomLeft, cornerLength, cornerWidth, top: false, right: false),
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _frameColor.withOpacity(0.15),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, double length, double width,
      {required bool top, required bool right}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: _frameColor, width: width) : BorderSide.none,
            bottom: !top ? BorderSide(color: _frameColor, width: width) : BorderSide.none,
            right: right ? BorderSide(color: _frameColor, width: width) : BorderSide.none,
            left: !right ? BorderSide(color: _frameColor, width: width) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIdleHint() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: _orange, size: 22),
              const SizedBox(height: 8),
              const Text(
                'الكاميرا وهمية — استخدم الإدخال اليدوي',
                style: TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _showManualInput,
                  icon: const Icon(Icons.keyboard, color: Colors.white, size: 18),
                  label: const Text(
                    'إدخال رقم التسلسل',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _frameColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _frameColor.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _scanState == _ScanState.unknown
              ? _buildUnknownContent()
              : _scanState == _ScanState.invalid
                  ? _buildInvalidContent()
                  : _buildOperationContent(),
        ),
      ),
    );
  }

  Widget _buildUnknownContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: _red, size: 32),
        const SizedBox(height: 8),
        const Text(
          'هذا الملصق مجهول غير تابع للنظام',
          style: TextStyle(color: _red, fontSize: 15, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _showManualInput,
          icon: const Icon(Icons.keyboard, color: kPrimary, size: 16),
          label: const Text('إدخال رقم آخر', style: TextStyle(color: kPrimary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildInvalidContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, color: _orange, size: 32),
        const SizedBox(height: 8),
        const Text(
          'رقم التسلسل غير صالح',
          style: TextStyle(color: _orange, fontSize: 15, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'الصيغة المطلوبة: TA1-XXXX',
          style: TextStyle(color: kTextSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _showManualInput,
          icon: const Icon(Icons.keyboard, color: kPrimary, size: 16),
          label: const Text('إدخال رقم آخر', style: TextStyle(color: kPrimary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildOperationContent() {
    final op = _scannedOp!;
    final isDeleted = _scanState == _ScanState.deleted;
    final statusColor = isDeleted
        ? _red
        : op.status == OperationStatus.confirmed
            ? _green
            : _orange;
    final statusLabel = isDeleted
        ? 'محذوفة'
        : op.status == OperationStatus.confirmed
            ? 'مؤكدة'
            : op.status == OperationStatus.delivered
                ? 'تم التوصيل'
                : 'غير مؤكدة';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _displayCustomerName(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(op.amount),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text('د.ع', style: TextStyle(color: _gray, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.qr_code_2, color: _gray, size: 14),
            const SizedBox(width: 4),
            Text(
              op.serial,
              style: const TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        if (isDeleted) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.35), width: 1),
            ),
            child: const Text(
              'هذه العملية في سلة المحذوفات',
              style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _showManualInput,
            icon: const Icon(Icons.keyboard, color: kPrimary, size: 16),
            label: const Text('إدخال رقم آخر', style: TextStyle(color: kPrimary, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}