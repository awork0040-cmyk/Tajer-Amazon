import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';

const Color kOrange = Color(0xFFF0883E);
const Color kGreen = Color(0xFF3FB950);
const Color kDanger = Color(0xFFE53935);

enum _ScanFeedback { none, success, duplicate, unknown, error }

class SortingCameraScreen extends StatefulWidget {
  const SortingCameraScreen({Key? key}) : super(key: key);
  @override
  State<SortingCameraScreen> createState() => _SortingCameraScreenState();
}

class _SortingCameraScreenState extends State<SortingCameraScreen> {
  final Set<String> _scannedOpIds = {};
  Operation? _lastScanned;
  _ScanFeedback _feedback = _ScanFeedback.none;

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // حالة الإطار
  // ═══════════════════════════════════════════════════════════

  Color get _frameColor {
    switch (_feedback) {
      case _ScanFeedback.success:
        return kGreen;
      case _ScanFeedback.duplicate:
        return kOrange;
      case _ScanFeedback.unknown:
      case _ScanFeedback.error:
        return kDanger;
      case _ScanFeedback.none:
        return Colors.white;
    }
  }

  int get _totalVisibleOps {
    return DataService.instance.operations
        .where((o) =>
            o.status == OperationStatus.unconfirmed ||
            o.status == OperationStatus.confirmed)
        .length;
  }

  // ═══════════════════════════════════════════════════════════
  // منطق المسح
  // ═══════════════════════════════════════════════════════════

  void _processScannedSerial(String rawSerial) {
    final serial = rawSerial.trim();
    if (serial.isEmpty) return;

    // تحقق من الصيغة
    final formatOk = RegExp(r'^TA1-\d+$').hasMatch(serial);
    if (!formatOk) {
      _setFeedback(_ScanFeedback.error);
      _showSnack('رقم غير صالح', kDanger);
      return;
    }

    final op = DataService.instance.getOperationBySerial(serial);

    // غير موجود
    if (op == null) {
      _setFeedback(_ScanFeedback.unknown);
      _showSnack('ملصق مجهول — غير تابع للنظام', kDanger);
      return;
    }

    // محذوف
    if (op.status == OperationStatus.deleted || op.deletedAt != null) {
      _setFeedback(_ScanFeedback.unknown);
      _showSnack('الملصق تابع لعملية محذوفة', kDanger);
      return;
    }

    // تم التوصيل — لا يظهر في الفرز
    if (op.status == OperationStatus.delivered) {
      _setFeedback(_ScanFeedback.error);
      _showSnack('هذه العملية تم توصيلها بالفعل', kOrange);
      return;
    }

    // مكرر
    if (_scannedOpIds.contains(op.id)) {
      _setFeedback(_ScanFeedback.duplicate);
      _showSnack('تم مسح هذه العملية مسبقاً', kOrange);
      return;
    }

    // نجاح
    setState(() {
      _scannedOpIds.add(op.id);
      _lastScanned = op;
    });
    _setFeedback(_ScanFeedback.success);
  }

  void _setFeedback(_ScanFeedback fb) {
    setState(() => _feedback = fb);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _feedback == fb) {
        setState(() => _feedback = _ScanFeedback.none);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // إدخال يدوي
  // ═══════════════════════════════════════════════════════════

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
                    'مسح',
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
      _processScannedSerial(result);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════

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
            'بدء الفرز',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showSnack('الكشاف غير متاح — الكاميرا وهمية', kOrange);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: const Icon(Icons.flash_off, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildCameraMock(),
            _buildTopCounter(),
            _buildScanFrame(),
            _buildInfoCard(),
            _buildManualButton(),
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

  Widget _buildTopCounter() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, color: kPrimary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_scannedOpIds.length} / $_totalVisibleOps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    const double frameSize = 260;
    const double cornerLength = 32;
    const double cornerWidth = 4;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _frameColor.withOpacity(_feedback == _ScanFeedback.none ? 0.0 : 0.45),
              blurRadius: 25,
              spreadRadius: 4,
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
                width: 250,
                height: 250,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  Widget _buildInfoCard() {
    if (_lastScanned == null && _feedback == _ScanFeedback.none) {
      return const SizedBox.shrink();
    }
    if (_lastScanned == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _frameColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _frameColor.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  _feedback == _ScanFeedback.duplicate
                      ? Icons.content_copy
                      : _feedback == _ScanFeedback.unknown
                          ? Icons.help_outline
                          : Icons.error_outline,
                  color: _frameColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _feedback == _ScanFeedback.duplicate
                        ? 'الملصق ممسوح مسبقاً'
                        : _feedback == _ScanFeedback.unknown
                            ? 'ملصق مجهول'
                            : 'خطأ في المسح',
                    style: TextStyle(
                      color: _frameColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final op = _lastScanned!;
    final customer = DataService.instance.getCustomerById(op.customerId);
    final customerName = customer?.primaryName ?? op.customerName;
    final racks = customer?.shelfNumbers ?? [];
    final batchId = customer?.assignedBatch;

    String batchLabel = '';
    if (batchId != null) {
      const arabic = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة'];
      if (batchId >= 0 && batchId < arabic.length) {
        batchLabel = 'الوجبة ${arabic[batchId]}';
      } else {
        batchLabel = 'الوجبة ${batchId + 1}';
      }
    }

    final isConfirmed = op.status == OperationStatus.confirmed;
    final statusColor = isConfirmed ? kGreen : kOrange;
    final statusLabel = isConfirmed ? 'مؤكدة' : 'غير مؤكدة';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGreen.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kGreen.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رقم الرف — كبير
              if (racks.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPrimary.withOpacity(0.4), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الرف',
                        style: TextStyle(color: kPrimary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        racks.join('، '),
                        style: const TextStyle(
                          color: kPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kOrange.withOpacity(0.4), width: 1),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'الرف',
                        style: TextStyle(color: kOrange, fontSize: 11),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'بدون رف',
                        style: TextStyle(
                          color: kOrange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (batchLabel.isNotEmpty) ...[
                    const Icon(Icons.restaurant, color: kTextSecondary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      batchLabel,
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    '${op.amount == 0 ? "هدية" : _formatAmount(op.amount)} ${op.amount > 0 ? "د.ع" : ""}',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: kTextSecondary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    op.serial,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildManualButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showManualInput,
              icon: const Icon(Icons.keyboard, color: kPrimary, size: 18),
              label: const Text(
                'إدخال يدوي',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPrimary.withOpacity(0.6), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}