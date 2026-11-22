import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import '../widgets/animated_list_item.dart';
import 'customer_operations_screen.dart' as cust_ops;
import 'customer_profile_screen.dart';
import 'delivery_receipt_screen.dart';
import 'scanner_screen.dart';

const Color kOrange = Color(0xFFF0883E);
const Color kGreen = Color(0xFF3FB950);
const Color kSilver = Color(0xFFB0BEC5);
const Color kSoftWhite = Color(0xFFE0E0E0);
const Color kDanger = Color(0xFFE53935);

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  int _currentTab = 0;
  late int _deliverySubTab;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _deliverySubTab = DataService.instance.lastDeliverySubTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final isAm = dt.hour < 12;
    final period = isAm ? 'ص' : 'م';
    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d  $hour12:$min $period';
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
  // البحث بالسكنر
  // ═══════════════════════════════════════════════════════════

  Future<void> _openScannerForSearch() async {
    final serial = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (serial == null || serial.isEmpty) return;

    final info = DataService.instance.getOperationCardInfo(serial);
    if (info == null) {
      _showSnack('لا توجد عملية بهذا الرمز', kDanger);
      return;
    }

    if (info.isDelivery || info.isDelivered) {
      _showDeliveryWarning(info);
      return;
    }

    // غير مؤكدة أو مؤكدة → فتح بطاقة العميل مع تمييز العملية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => cust_ops.CustomerOperationsScreen(
          customerId: info.customerId,
          customerName: info.customerName,
          highlightedOperationId: info.operation.id,
          hideScanner: false,
        ),
      ),
    );
  }

  void _showDeliveryWarning(OperationCardInfo info) {
    final isDelivered = info.isDelivered;
    final custOps = DataService.instance.getOperationsForCustomer(info.customerId);
    final List<Operation> targetOps = isDelivered
        ? custOps.where((o) => o.status == OperationStatus.delivered).toList()
        : custOps.where((o) => o.status == OperationStatus.outForDelivery).toList();

    DateTime? date;
    if (targetOps.isNotEmpty) {
      date = isDelivered
          ? targetOps.map((o) => o.deliveredAt ?? o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : targetOps.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final totalAmount = targetOps.fold<int>(0, (s, o) => s + o.amount);
    final dateStr = date != null ? _formatDate(date) : '—';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isDelivered ? 'الطلب تم توصيله' : 'الطلب جاري التوصيل',
            style: const TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDelivered
                    ? 'هذا الطلب رقم ${info.operation.serial} يخص العميل "${info.customerName}"، وقد سُلّم للعميل بتاريخ $dateStr.'
                    : 'هذا الطلب رقم ${info.operation.serial} يخص العميل "${info.customerName}"، ويجب أن يكون قد سُلّم للسائق مع باقي الطلبات بتاريخ $dateStr.',
                style: const TextStyle(color: kTextSecondary, fontSize: 13.5, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              // معاينة البطاقة
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFullDeliveryScreen(
                    info.customerId,
                    info.customerName,
                    isDeliveredTab: isDelivered,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _neumorphicDecoration(radius: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 40,
                        decoration: BoxDecoration(
                          color: isDelivered ? kSoftWhite : kSilver,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(info.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${targetOps.length} طلبات — ${_formatAmount(totalAmount)} د.ع', style: const TextStyle(color: kSilver, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left, color: kTextSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الوصل
  // ═══════════════════════════════════════════════════════════

  void _showReceiptDialog(String customerId, String customerName, List<Operation> ops) {
    final customer = DataService.instance.getCustomerById(customerId);
    if (customer == null || ops.isEmpty) return;
    final total = ops.fold<int>(0, (sum, o) => sum + o.amount);
    final latestDate = ops.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

    showDialog(
      context: context,
      builder: (_) => DeliveryReceiptScreen(
        customer: customer,
        operations: ops,
        totalAmount: total,
        dateTime: latestDate,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الشاشة الكاملة للتوصيل
  // ═══════════════════════════════════════════════════════════

  void _openFullDeliveryScreen(String customerId, String customerName, {required bool isDeliveredTab}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DeliveryFullScreen(
          customerId: customerId,
          customerName: customerName,
          isDeliveredTab: isDeliveredTab,
          formatAmount: _formatAmount,
          formatDate: _formatDate,
          onCancelOrder: _onCancelSingleOrder,
        ),
      ),
    );
  }

  void _onCancelSingleOrder(String opId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إلغاء الطلب', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text('سيُنقل هذا الطلب إلى سلة المحذوفات.\nوعند استعادته سيرجع لنفس حالته السابقة.', style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
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
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    DataService.instance.cancelDeliveryOrder(opId);
                    Navigator.pop(ctx);
                    _showSnack('تم نقل الطلب لسلة المحذوفات', kDanger);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // تسليم للسائق (مع تأكيد)
  // ═══════════════════════════════════════════════════════════

  void _onDeliverToDriver(String customerId, String customerName, {List<Operation>? targetOps}) {
    final confirmedOps = targetOps ??
        DataService.instance.getOperationsForCustomer(customerId).where((o) => o.status == OperationStatus.confirmed).toList();
    if (confirmedOps.isEmpty) return;

    final total = confirmedOps.fold<int>(0, (s, o) => s + o.amount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تسليم للسائق', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          'هل تريد تسليم طلبات العميل "$customerName" للسائق؟\nسيتم نقل ${confirmedOps.length} طلب (${_formatAmount(total)} د.ع) إلى حالة "جاري التوصيل".',
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
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
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    for (final op in confirmedOps) {
                      DataService.instance.updateOperationStatus(op.id, OperationStatus.outForDelivery);
                    }
                    Navigator.pop(ctx);
                    _showSnack('تم التسليم للسائق', kSilver);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary.withOpacity(0.78),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('تسليم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // تم التوصيل (مع تأكيد)
  // ═══════════════════════════════════════════════════════════

  void _onMarkAsDelivered(String customerId, String customerName) {
    final ops = DataService.instance.getOperationsForCustomer(customerId).where((o) => o.status == OperationStatus.outForDelivery).toList();
    if (ops.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد التوصيل', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          'هل تم توصيل طلبات $customerName بنجاح؟\nسيتم نقل ${ops.length} طلب إلى الأرشيف (تم التوصيل).',
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
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
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    for (final op in ops) {
                      DataService.instance.updateOperationStatus(op.id, OperationStatus.delivered);
                    }
                    Navigator.pop(ctx);
                    _showSnack('تم التوصيل بنجاح', kGreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary.withOpacity(0.78),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('تم التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // إلغاء الطلب (كل الطلبات)
  // ═══════════════════════════════════════════════════════════

  void _onCancelOrder(String customerId) {
    final ops = DataService.instance.getOperationsForCustomer(customerId).where((o) => o.status == OperationStatus.outForDelivery).toList();
    if (ops.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إلغاء الطلب', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('سيتم نقل ${ops.length} طلب إلى سلة المحذوفات.\nوعند استعادتها سترجع لنفس حالتها السابقة.', style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
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
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    for (final op in ops) {
                      DataService.instance.cancelDeliveryOrder(op.id);
                    }
                    Navigator.pop(ctx);
                    _showSnack('تم نقل الطلبات لسلة المحذوفات', kDanger);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // دمج البطاقات (اختيار متعدد)
  // ═══════════════════════════════════════════════════════════

  Future<void> _onMergeTap(String customerId, String customerName, {String? excludeBatchKey}) async {
    // جمع كل البطاقات المتاحة للعميل
    final confirmedCards = DataService.instance.getConfirmedCardsForCustomer(customerId);
    final unconfirmedOps = DataService.instance
        .getOperationsForCustomer(customerId)
        .where((o) => o.status == OperationStatus.unconfirmed)
        .toList();

    final options = <_MergeCardOption>[];

    for (final card in confirmedCards) {
      options.add(_MergeCardOption(
        batchKey: card.batchKey,
        isConfirmed: true,
        customerName: card.customerName,
        ordersCount: card.ordersCount,
        totalAmount: card.totalAmount,
        date: card.date,
      ));
    }

    if (unconfirmedOps.isNotEmpty) {
      final totalAmount = unconfirmedOps.fold<int>(0, (s, o) => s + o.amount);
      final firstDate = unconfirmedOps.map((o) => o.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
      options.add(_MergeCardOption(
        batchKey: '_unconfirmed_',
        isConfirmed: false,
        customerName: customerName,
        ordersCount: unconfirmedOps.length,
        totalAmount: totalAmount,
        date: firstDate,
      ));
    }

    if (options.length < 2) return;

    // البطاقة الأساسية: التي ضغط عليها المستخدم
    final primaryKey = excludeBatchKey;
    final primaryOption = primaryKey != null
        ? options.firstWhere((o) => o.batchKey == primaryKey, orElse: () => options.first)
        : null;

    final result = await showDialog<_MergeSelectionResult>(
      context: context,
      builder: (ctx) => _MergeSelectionDialog(
        customerName: customerName,
        options: options,
        primaryBatchKey: primaryOption?.batchKey,
        formatAmount: _formatAmount,
        formatDate: _formatDate,
      ),
    );

    if (result == null || result.selectedKeys.isEmpty) return;

    // تحديد البطاقة الأساسية (الأولى إن لم تُحدد)
    final primary = primaryOption ?? options.firstWhere((o) => result.selectedKeys.contains(o.batchKey));
    final others = result.selectedKeys.where((k) => k != primary.batchKey).toList();

    // إذا كان ضمن المحدد أي بطاقة غير مؤكدة → كل شيء يرجع لغير مؤكد
    final hasUnconfirmedSelected = result.selectedKeys.any((k) {
      final opt = options.firstWhere((o) => o.batchKey == k);
      return !opt.isConfirmed;
    });

    if (hasUnconfirmedSelected) {
      // إرجاع البطاقات المؤكدة المحددة إلى غير مؤكدة
      for (final key in result.selectedKeys) {
        if (key == '_unconfirmed_') continue;
        DataService.instance.mergeSpecificConfirmedBatch(customerId, key);
      }
      _showSnack('تم الدمج وإرجاعها لغير مؤكدة', kOrange);
    } else {
      // الكل مؤكد → دمج في البطاقة الأساسية
      DataService.instance.mergeConfirmedCardsInto(customerId, primary.batchKey, others);
      _showSnack('تم دمج البطاقات', kGreen);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // حذف بطاقة
  // ═══════════════════════════════════════════════════════════

  void _confirmDeleteCustomerCard(String customerId, String customerName, List<Operation> ops) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف الطلبات', style: TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          'سيتم حذف ${ops.length} طلب للعميل ($customerName) ونقلها إلى سلة المحذوفات. هل تريد المتابعة؟',
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تراجع', style: TextStyle(color: kTextSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    for (final op in ops) {
                      DataService.instance.deleteOperation(op.id);
                    }
                    _showSnack('تم نقل الطلبات إلى سلة المحذوفات', kDanger);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kDanger),
                  child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // البتن شيت
  // ═══════════════════════════════════════════════════════════

  void _showCardLongPressSheet({
    required String customerId,
    required String customerName,
    required List<Operation> cardOps,
    required bool canMerge,
    String? excludeBatchKey,
    bool showMerge = true,
    bool showDelete = true,
  }) {
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
                const SizedBox(height: 14),
                Text(customerName, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                if (showMerge && canMerge)
                  ListTile(
                    leading: const Icon(Icons.merge_type, color: kOrange),
                    title: const Text('دمج', style: TextStyle(color: kOrange, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _onMergeTap(customerId, customerName, excludeBatchKey: excludeBatchKey);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: kPrimary),
                  title: const Text('ملف العميل', style: TextStyle(color: kTextPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerProfileScreen(customerId: customerId)),
                    );
                  },
                ),
                if (showDelete)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: kDanger),
                    title: const Text('حذف', style: TextStyle(color: kDanger, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteCustomerCard(customerId, customerName, cardOps);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // رأس البطاقة
  // ═══════════════════════════════════════════════════════════

  Widget _buildCardHeader({
    required String customerName,
    required int ordersCount,
    required int totalAmount,
    required Color accentColor,
    DateTime? date,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('${_formatAmount(totalAmount)} د.ع — $ordersCount طلبات', style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (date != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatDate(date),
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildMergeActionBanner({
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text('لديه طلبات مؤكدة سابقة.', style: TextStyle(color: color, fontSize: 11)),
          ),
          Material(
            color: color.withOpacity(0.22),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'دمج',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
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
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
          leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
          title: const Text('إدارة الطلبات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: ListenableBuilder(
          listenable: DataService.instance,
          builder: (context, _) {
            List<Operation> currentOps;
            if (_currentTab == 0) {
              currentOps = DataService.instance.getUnconfirmedOperations();
            } else if (_currentTab == 1) {
              currentOps = DataService.instance.getConfirmedOperations();
            } else {
              currentOps = _deliverySubTab == 0
                  ? DataService.instance.getOutForDeliveryOperations()
                  : DataService.instance.getDeliveredOperations();
            }

            final filteredOps = _searchQuery.isEmpty
                ? currentOps
                : currentOps.where((o) => DataService.instance.normalizeArabic(o.customerName).contains(DataService.instance.normalizeArabic(_searchQuery))).toList();

            final grouped = _groupByCustomer(filteredOps);
            final totalAmount = filteredOps.fold<int>(0, (sum, o) => sum + o.amount);

            return Column(
              children: [
                const SizedBox(height: 10),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: _buildMainTabs()),
                const SizedBox(height: 10),
                if (_currentTab == 2) ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: _buildDeliverySubTabs()),
                  const SizedBox(height: 10),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: _neumorphicDecoration(radius: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('العملاء', '${grouped.length}'),
                        Container(width: 1, height: 20, color: Colors.white12),
                        _buildStatItem('الطلبات', '${filteredOps.length}'),
                        Container(width: 1, height: 20, color: Colors.white12),
                        _buildStatItem('المبلغ', _formatAmount(totalAmount)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildOrdersList(
                    grouped,
                    tabIndex: _currentTab,
                    isConfirmed: _currentTab == 1,
                    isDelivery: _currentTab == 2 && _deliverySubTab == 0,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // شريط البحث + زر المسح (نصفين)
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    final showScan = _currentTab != 2;
    return Container(
      height: 48,
      decoration: _neumorphicDecoration(),
      child: Row(
        children: [
          if (showScan) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                onTap: _openScannerForSearch,
                child: Container(
                  width: 130,
                  height: 48,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner, color: kPrimary, size: 20),
                      SizedBox(width: 6),
                      Text('مسح QR', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 24, color: Colors.white12),
          ],
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم...',
                hintStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16, color: kTextSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // التبويبات
  // ═══════════════════════════════════════════════════════════

  Widget _buildMainTabs() {
    const titles = ['غير مؤكدة', 'مؤكدة', 'حالة التوصيل'];
    const colors = [kOrange, kGreen, kSilver];
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        const int count = 3;
        final double tabWidth = w / count;
        final double indicatorWidth = tabWidth - 8;
        final double rightPos = _currentTab * tabWidth + 4;
        final Color activeColor = colors[_currentTab];

        return Container(
          height: 50,
          decoration: _neumorphicDecoration(radius: 12),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                right: rightPos, top: 4, bottom: 4, width: indicatorWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: List.generate(count, (i) {
                    final isActive = _currentTab == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _currentTab = i;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              color: isActive ? colors[i].withOpacity(0.76) : kTextSecondary.withOpacity(0.72),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            child: Text(titles[i]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliverySubTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double tabWidth = w / 2;
        final double indicatorWidth = tabWidth - 8;
        final double rightPos = _deliverySubTab * tabWidth + 4;

        return Container(
          height: 45,
          decoration: _neumorphicDecoration(radius: 12),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                right: rightPos, top: 4, bottom: 4, width: indicatorWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: kSilver.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _buildSubTabBtn('جاري التوصيل', 0),
                    _buildSubTabBtn('تم التوصيل', 1),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubTabBtn(String title, int index) {
    final isActive = _deliverySubTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          DataService.instance.lastDeliverySubTab = index;
          setState(() {
            _deliverySubTab = index;
            _searchController.clear();
            _searchQuery = '';
          });
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              color: Colors.white.withOpacity(isActive ? 0.76 : 0.68),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Map<String, List<Operation>> _groupByCustomer(List<Operation> ops) {
    final map = <String, List<Operation>>{};
    for (final op in ops) {
      map.putIfAbsent(op.customerId, () => []).add(op);
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════
  // القوائم
  // ═══════════════════════════════════════════════════════════

  Widget _buildOrdersList(
    Map<String, List<Operation>> grouped, {
    required int tabIndex,
    required bool isConfirmed,
    required bool isDelivery,
  }) {
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          isConfirmed ? 'لا توجد طلبات مؤكدة' : isDelivery ? 'لا توجد طلبات جاري توصيلها' : 'لا توجد طلبات',
          style: const TextStyle(color: kTextSecondary, fontSize: 14),
        ),
      );
    }

    if (isConfirmed) {
      final List<ConfirmedOrderCardData> confirmedCards = [];
      for (final customerId in grouped.keys) {
        confirmedCards.addAll(DataService.instance.getConfirmedCardsForCustomer(customerId));
      }
      confirmedCards.sort((a, b) => b.date.compareTo(a.date));

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: confirmedCards.length,
        itemBuilder: (context, index) {
          final card = confirmedCards[index];
          final allConfirmedCount = DataService.instance.getConfirmedCardsForCustomer(card.customerId).length;
          final hasUnconfirmedNew = DataService.instance
              .getOperationsForCustomer(card.customerId)
              .any((o) => o.status == OperationStatus.unconfirmed);
          final hasOtherConfirmed = allConfirmedCount > 1;
          final showAlertBanner = hasUnconfirmedNew || hasOtherConfirmed;

          return AnimatedListItem(
            key: ValueKey('confirmed_${card.batchKey}'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => cust_ops.CustomerOperationsScreen(
                          customerId: card.customerId,
                          customerName: card.customerName,
                          hideScanner: true,
                          canMergeFromCard: showAlertBanner,
                          onMergeRequested: () => _onMergeTap(card.customerId, card.customerName, excludeBatchKey: card.batchKey),
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showCardLongPressSheet(
                    customerId: card.customerId,
                    customerName: card.customerName,
                    cardOps: card.operations,
                    canMerge: showAlertBanner,
                    excludeBatchKey: card.batchKey,
                  ),
                  child: Container(
                    decoration: _neumorphicDecoration(),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16, left: 12, top: 12, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCardHeader(
                                customerName: card.customerName,
                                ordersCount: card.ordersCount,
                                totalAmount: card.totalAmount,
                                accentColor: kGreen,
                                date: card.date,
                              ),
                              if (showAlertBanner)
                                _buildMergeActionBanner(
                                  color: kGreen,
                                  onTap: () => _onMergeTap(card.customerId, card.customerName, excludeBatchKey: card.batchKey),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _showReceiptDialog(card.customerId, card.customerName, card.operations),
                                      style: TextButton.styleFrom(
                                        backgroundColor: kPrimary.withOpacity(0.15),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(0, 46),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('وصل', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _onDeliverToDriver(card.customerId, card.customerName, targetOps: card.operations),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary.withOpacity(0.78),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(0, 46),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: const Text('تسليم للسائق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(top: 0, bottom: 0, right: 0, child: Container(width: 6, color: kGreen)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aMax = a.value.map((o) => o.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
      final bMax = b.value.map((o) => o.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
      return bMax.compareTo(aMax);
    });

    final isDeliveredSubTab = tabIndex == 2 && _deliverySubTab == 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final customerId = entry.key;
        final ops = entry.value;
        final customerName = ops.first.customerName;
        final total = ops.fold<int>(0, (sum, o) => sum + o.amount);

        final confirmedCardsCount = DataService.instance.getConfirmedCardsForCustomer(customerId).length;
        final hasConfirmedOps = confirmedCardsCount > 0;
        final showMergeBtn = tabIndex == 0 && hasConfirmedOps;

        final firstUnconfirmedDate = DataService.instance.getFirstUnconfirmedDateForCustomer(customerId);
        final deliveredDate = ops.map((o) => o.deliveredAt ?? o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
        final cardDate = tabIndex == 0
            ? firstUnconfirmedDate
            : (isDeliveredSubTab ? deliveredDate : null);

        Color stripColor = isDelivery ? kSilver : kOrange;
        if (isDeliveredSubTab) stripColor = kSoftWhite;

        return AnimatedListItem(
          key: ValueKey('${tabIndex}_${_deliverySubTab}_$customerId'),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (tabIndex == 2) {
                    _openFullDeliveryScreen(customerId, customerName, isDeliveredTab: isDeliveredSubTab);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => cust_ops.CustomerOperationsScreen(
                          customerId: customerId,
                          customerName: customerName,
                          hideScanner: false,
                          canMergeFromCard: showMergeBtn,
                          onMergeRequested: () => _onMergeTap(customerId, customerName),
                        ),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (tabIndex == 0) {
                    _showCardLongPressSheet(
                      customerId: customerId,
                      customerName: customerName,
                      cardOps: ops,
                      canMerge: hasConfirmedOps,
                    );
                  } else if (tabIndex == 2 && !isDeliveredSubTab) {
                    _showCardLongPressSheet(
                      customerId: customerId,
                      customerName: customerName,
                      cardOps: ops,
                      canMerge: false,
                      showMerge: false,
                      showDelete: false,
                    );
                  } else if (tabIndex == 2 && isDeliveredSubTab) {
                    _showCardLongPressSheet(
                      customerId: customerId,
                      customerName: customerName,
                      cardOps: ops,
                      canMerge: false,
                      showMerge: false,
                      showDelete: true,
                    );
                  }
                },
                child: Container(
                  decoration: _neumorphicDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16, left: 12, top: 12, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCardHeader(
                              customerName: customerName,
                              ordersCount: ops.length,
                              totalAmount: total,
                              accentColor: stripColor,
                              date: cardDate,
                            ),
                            if (showMergeBtn)
                              _buildMergeActionBanner(
                                color: kOrange,
                                onTap: () => _onMergeTap(customerId, customerName),
                              ),
                            if (isDelivery) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _onCancelOrder(customerId),
                                      style: TextButton.styleFrom(
                                        backgroundColor: kDanger.withOpacity(0.15),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(0, 46),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('إلغاء الطلب', style: TextStyle(color: kDanger, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _onMarkAsDelivered(customerId, customerName),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary.withOpacity(0.78),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        minimumSize: const Size(0, 46),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: const Text('تم التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(top: 0, bottom: 0, right: 0, child: Container(width: 6, color: stripColor)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// الشاشة الكاملة للتوصيل
// ═══════════════════════════════════════════════════════════

class _DeliveryFullScreen extends StatelessWidget {
  final String customerId;
  final String customerName;
  final bool isDeliveredTab;
  final String Function(int) formatAmount;
  final String Function(DateTime) formatDate;
  final void Function(String opId) onCancelOrder;

  const _DeliveryFullScreen({
    required this.customerId,
    required this.customerName,
    required this.isDeliveredTab,
    required this.formatAmount,
    required this.formatDate,
    required this.onCancelOrder,
  });

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final targetStatus = isDeliveredTab ? OperationStatus.delivered : OperationStatus.outForDelivery;
          final ops = DataService.instance
              .getOperationsForCustomer(customerId)
              .where((o) => o.status == targetStatus)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final totalAmount = ops.fold<int>(0, (s, o) => s + o.amount);

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              toolbarHeight: 70,
              leadingWidth: 70,
              leading: Center(
                child: Container(
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
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                customerName,
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: _neumorphicDecoration(radius: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('الطلبات', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${ops.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(width: 1, height: 26, color: Colors.white12),
                          Column(
                            children: [
                              const Text('المبلغ', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${formatAmount(totalAmount)} د.ع', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ops.isEmpty
                        ? const Center(child: Text('لا توجد طلبات', style: TextStyle(color: kTextSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: ops.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final op = ops[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: _neumorphicDecoration(radius: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            op.serial,
                                            style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                            textDirection: TextDirection.ltr,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${formatAmount(op.amount)} د.ع',
                                            style: const TextStyle(color: kTextSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatDate(op.createdAt),
                                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                                    ),
                                    if (!isDeliveredTab) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: kDanger),
                                        tooltip: 'إلغاء الطلب',
                                        onPressed: () => onCancelOrder(op.id),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// نافذة اختيار البطاقات للدمج
// ═══════════════════════════════════════════════════════════

class _MergeCardOption {
  final String batchKey;
  final bool isConfirmed;
  final String customerName;
  final int ordersCount;
  final int totalAmount;
  final DateTime date;

  const _MergeCardOption({
    required this.batchKey,
    required this.isConfirmed,
    required this.customerName,
    required this.ordersCount,
    required this.totalAmount,
    required this.date,
  });
}

class _MergeSelectionResult {
  final Set<String> selectedKeys;
  const _MergeSelectionResult(this.selectedKeys);
}

class _MergeSelectionDialog extends StatefulWidget {
  final String customerName;
  final List<_MergeCardOption> options;
  final String? primaryBatchKey;
  final String Function(int) formatAmount;
  final String Function(DateTime) formatDate;

  const _MergeSelectionDialog({
    required this.customerName,
    required this.options,
    this.primaryBatchKey,
    required this.formatAmount,
    required this.formatDate,
  });

  @override
  State<_MergeSelectionDialog> createState() => _MergeSelectionDialogState();
}

class _MergeSelectionDialogState extends State<_MergeSelectionDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};
    if (widget.primaryBatchKey != null) {
      _selected.add(widget.primaryBatchKey!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'دمج بطاقات ${widget.customerName}',
          style: const TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر البطاقات التي تريد دمجها. إذا اخترت بطاقة غير مؤكدة، سترجع كل البطاقات المختارة إلى "غير مؤكدة" لاستكمال التأكيد.',
                style: TextStyle(color: kTextSecondary, fontSize: 12.5, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final opt = widget.options[i];
                    final isPrimary = widget.primaryBatchKey == opt.batchKey;
                    final isSelected = _selected.contains(opt.batchKey);
                    final color = opt.isConfirmed ? kGreen : kOrange;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isPrimary
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(opt.batchKey);
                                } else {
                                  _selected.add(opt.batchKey);
                                }
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSurfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.white.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? color : Colors.transparent,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        opt.isConfirmed ? 'بطاقة مؤكدة' : 'بطاقة غير مؤكدة',
                                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      if (isPrimary) ...[
                                        const SizedBox(width: 6),
                                        const Text('(أساسية)', style: TextStyle(color: kTextSecondary, fontSize: 10)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${opt.ordersCount} طلبات — ${widget.formatAmount(opt.totalAmount)} د.ع',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(widget.formatDate(opt.date),
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selected.length >= 2
                      ? () => Navigator.pop(context, _MergeSelectionResult(_selected))
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.length >= 2 ? kOrange : kOrange.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('دمج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}