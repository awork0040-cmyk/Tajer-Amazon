import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import 'delivery_receipt_screen.dart';
import 'scanner_screen.dart';

const Color _kOrange = Color(0xFFF0883E);
const Color _kGreen = Color(0xFF3FB950);
const Color _kDanger = Color(0xFFE53935);

class CustomerOperationsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final bool autoOpenScanner;
  final bool hideScanner;
  final bool canMergeFromCard;
  final VoidCallback? onMergeRequested;
  final String? highlightedOperationId;

  const CustomerOperationsScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    this.autoOpenScanner = false,
    this.hideScanner = false,
    this.canMergeFromCard = false,
    this.onMergeRequested,
    this.highlightedOperationId,
  }) : super(key: key);

  @override
  State<CustomerOperationsScreen> createState() => _CustomerOperationsScreenState();
}

class _CustomerOperationsScreenState extends State<CustomerOperationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedOpId;

  @override
  void initState() {
    super.initState();
    _highlightedOpId = widget.highlightedOperationId;

    if (widget.autoOpenScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openScanner());
    }

    if (_highlightedOpId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToHighlighted);
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightedOpId = null);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlighted() {
    if (_highlightedOpId == null) return;

    final ops = DataService.instance.getDisplayableOperationsForCustomer(widget.customerId);
    ops.sort((a, b) {
      int priority(OperationStatus s) => s == OperationStatus.unconfirmed ? 0 : 1;
      final p = priority(a.status).compareTo(priority(b.status));
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });

    final idx = ops.indexWhere((o) => o.id == _highlightedOpId);
    if (idx < 0 || !_scrollController.hasClients) return;

    const estimatedCardHeight = 78.0;
    final targetOffset = idx * estimatedCardHeight;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = targetOffset.clamp(0.0, maxExtent);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
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

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(
        color: const Color(0xFF1C2733),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5)),
            child: Icon(icon, color: Colors.white, size: 24),
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

  Color _statusColor(OperationStatus s) {
    switch (s) {
      case OperationStatus.unconfirmed:
        return _kOrange;
      case OperationStatus.confirmed:
        return _kGreen;
      default:
        return kTextSecondary;
    }
  }

  String _statusLabel(OperationStatus s) {
    switch (s) {
      case OperationStatus.unconfirmed:
        return 'غير مؤكدة';
      case OperationStatus.confirmed:
        return 'مؤكدة';
      default:
        return 'أخرى';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // المسح (حقيقي)
  // ═══════════════════════════════════════════════════════════

  Future<void> _openScanner() async {
    final serial = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (serial == null || serial.isEmpty || !mounted) return;

    final op = DataService.instance.getOperationBySerial(serial);
    if (op == null || op.status == OperationStatus.deleted) {
      _showSnack('لا توجد عملية بهذا الرمز', _kDanger);
      return;
    }

    if (op.customerId != widget.customerId) {
      _showSnack('هذا الطلب لا يخص هذا العميل', _kDanger);
      return;
    }

    if (op.status == OperationStatus.unconfirmed) {
      DataService.instance.confirmOperation(op.id);
      final remaining = DataService.instance
          .getDisplayableOperationsForCustomer(widget.customerId)
          .where((o) => o.status == OperationStatus.unconfirmed)
          .length;

      if (remaining == 0) {
        _showSnack('تم تأكيد جميع الطلبات بنجاح', _kGreen);
      } else {
        _showSnack('تم تأكيد الطلب ${op.serial}', _kGreen);
      }
    } else if (op.status == OperationStatus.confirmed) {
      _showSnack('هذا الطلب مؤكد بالفعل', _kGreen);
    } else {
      _showSnack('هذا الطلب ليس في حالة انتظار التأكيد', _kOrange);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // تعديل السعر
  // ═══════════════════════════════════════════════════════════

  Future<void> _editOperationPrice(Operation op) async {
    final controller = TextEditingController(text: op.amount.toString());
    final newPrice = await showDialog<int>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تعديل السعر',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: kTextPrimary),
            decoration: const InputDecoration(
              labelText: 'السعر الجديد',
              labelStyle: TextStyle(color: kTextSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.replaceAll(',', '').trim());
                if (parsed != null && parsed >= 0) {
                  Navigator.pop(ctx, parsed);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (newPrice != null && mounted) {
      DataService.instance.updateOperation(op.id, newAmount: newPrice);
      _showSnack('تم تحديث السعر', _kGreen);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // إعادة طباعة (مع تأكيد)
  // ═══════════════════════════════════════════════════════════

  Future<void> _confirmReprintOperation(Operation op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إعادة طباعة', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('هل تريد إعادة طباعة ملصق الطلب ${op.serial}؟', style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  child: const Text('طباعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) {
      _showSnack('تم إرسال ${op.serial} للطباعة', _kGreen);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // إلغاء التأكيد (مع تأكيد)
  // ═══════════════════════════════════════════════════════════

  Future<void> _confirmUnconfirmOperation(Operation op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إلغاء التأكيد', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('هل تريد إلغاء تأكيد الطلب ${op.serial} وإرجاعه إلى "غير مؤكدة"؟', style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
                  child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) {
      DataService.instance.unconfirmOperation(op.id);
      _showSnack('تم إلغاء تأكيد ${op.serial}', _kOrange);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // حذف (مع تأكيد)
  // ═══════════════════════════════════════════════════════════

  Future<void> _confirmDeleteOperation(Operation op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف الطلب', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('سيتم نقل الطلب ${op.serial} إلى سلة المحذوفات.\nهل تريد المتابعة؟', style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) {
      DataService.instance.deleteOperation(op.id);
      _showSnack('تم الحذف', _kDanger);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // البتن شيت
  // ═══════════════════════════════════════════════════════════

  void _showOperationOptions(Operation op) {
    final isConfirmedOp = op.status == OperationStatus.confirmed;
    final hasMerge = widget.canMergeFromCard && widget.onMergeRequested != null;

    final editPriceTile = ListTile(
      leading: const Icon(Icons.edit_outlined, color: kPrimary),
      title: const Text('تعديل السعر', style: TextStyle(color: kTextPrimary)),
      onTap: () {
        Navigator.pop(context);
        _editOperationPrice(op);
      },
    );

    final mergeTile = hasMerge
        ? ListTile(
            leading: const Icon(Icons.merge_type, color: _kOrange),
            title: const Text('دمج', style: TextStyle(color: _kOrange, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              widget.onMergeRequested!.call();
            },
          )
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(
                  op.serial,
                  style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w400),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                if (hasMerge) ...[
                  mergeTile!,
                  editPriceTile,
                ] else ...[
                  editPriceTile,
                ],
                if (isConfirmedOp)
                  ListTile(
                    leading: const Icon(Icons.undo, color: _kOrange),
                    title: const Text('إلغاء التأكيد', style: TextStyle(color: kTextPrimary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmUnconfirmOperation(op);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.print_outlined, color: kPrimary),
                  title: const Text('إعادة طباعة', style: TextStyle(color: kTextPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmReprintOperation(op);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: _kDanger),
                  title: const Text('حذف الطلب', style: TextStyle(color: _kDanger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteOperation(op);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // دمج البانر
  // ═══════════════════════════════════════════════════════════

  bool get _canShowMergeBanner {
    if (widget.onMergeRequested == null) return false;
    final hasConfirmed = DataService.instance.hasConfirmedOrders(widget.customerId);
    if (!hasConfirmed) return false;
    final hasUnconfirmed = DataService.instance
        .getOperationsForCustomer(widget.customerId)
        .any((o) => o.status == OperationStatus.unconfirmed);
    final confirmedCardsCount = DataService.instance.getConfirmedCardsForCustomer(widget.customerId).length;
    return hasUnconfirmed || confirmedCardsCount >= 2;
  }

  Widget _buildMergeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kOrange.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kOrange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _kOrange, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'يمكن دمج هذه الطلبات مع بطاقات أخرى لهذا العميل.',
              style: TextStyle(color: _kOrange, fontSize: 12),
            ),
          ),
          Material(
            color: _kOrange.withOpacity(0.22),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => widget.onMergeRequested?.call(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'دمج',
                  style: TextStyle(color: _kOrange, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // build
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final customer = DataService.instance.getCustomerById(widget.customerId);
          if (customer == null) return const Scaffold(backgroundColor: kScaffoldBg, body: Center(child: Text('العميل غير موجود')));

          final ops = DataService.instance.getDisplayableOperationsForCustomer(widget.customerId);

          ops.sort((a, b) {
            int priority(OperationStatus s) => s == OperationStatus.unconfirmed ? 0 : 1;
            final p = priority(a.status).compareTo(priority(b.status));
            if (p != 0) return p;
            return b.createdAt.compareTo(a.createdAt);
          });

          final unconfirmedCount = ops.where((o) => o.status == OperationStatus.unconfirmed).length;
          final confirmedCount = ops.where((o) => o.status == OperationStatus.confirmed).length;
          final totalAmount = ops.fold<int>(0, (sum, o) => sum + o.amount);
          final bool canPrintReceipt = unconfirmedCount == 0 && confirmedCount > 0;

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              title: Text(customer.primaryName, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: _neumorphicDecoration(radius: 12),
                      child: widget.hideScanner
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('مؤكدة', '$confirmedCount', kTextPrimary),
                                Container(width: 1, height: 30, color: Colors.white12),
                                _buildStatItem('الإجمالي', _formatAmount(totalAmount), kTextPrimary),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('غير مؤكدة', '$unconfirmedCount', _kOrange),
                                Container(width: 1, height: 30, color: Colors.white12),
                                _buildStatItem('مؤكدة', '$confirmedCount', _kGreen),
                                Container(width: 1, height: 30, color: Colors.white12),
                                _buildStatItem('الإجمالي', _formatAmount(totalAmount), kTextPrimary),
                              ],
                            ),
                    ),
                  ),
                  if (!widget.hideScanner) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        width: double.infinity, height: 45,
                        child: ElevatedButton.icon(
                          onPressed: _openScanner,
                          icon: const Icon(Icons.qr_code_scanner, size: 20, color: kPrimary),
                          label: const Text('مسح الطلبات', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C2733), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        ),
                      ),
                    ),
                  ],
                  if (_canShowMergeBanner) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _buildMergeBanner(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: ops.isEmpty
                        ? const Center(child: Text('لا توجد طلبات معلّقة', style: TextStyle(color: kTextSecondary)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: ops.length,
                            itemBuilder: (context, index) => _buildOperationCard(ops[index]),
                          ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: widget.hideScanner
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: canPrintReceipt
                              ? () => showDialog(
                                    context: context,
                                    builder: (_) => DeliveryReceiptScreen(
                                      customer: customer,
                                      operations: ops,
                                      totalAmount: totalAmount,
                                      dateTime: DateTime.now(),
                                    ),
                                  )
                              : null,
                          icon: Icon(Icons.print, color: canPrintReceipt ? Colors.white : Colors.white38),
                          label: Text('وصل', style: TextStyle(color: canPrintReceipt ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canPrintReceipt ? _kGreen : const Color(0xFF1C2733),
                            disabledBackgroundColor: const Color(0xFF1C2733),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildOperationCard(Operation op) {
    final color = _statusColor(op.status);
    final isHighlighted = _highlightedOpId == op.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: isHighlighted
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.18), blurRadius: 20, spreadRadius: 2),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () => _showOperationOptions(op),
          child: Container(
            decoration: _neumorphicDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 12, top: 12, bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(op.serial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), textDirection: TextDirection.ltr),
                            const SizedBox(height: 4),
                            Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
                        child: Text(_statusLabel(op.status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Positioned(top: 0, bottom: 0, right: 0, child: Container(width: 6, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}