import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF3FB950);
  static const Color _orange = Color(0xFFF0883E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPurgeOldOperations());
  }

  void _autoPurgeOldOperations() {
    // حذف تلقائي للعمليات التي مرّ عليها أكثر من 30 يوماً في السلة
    // TODO: إضافة Tombstones عند دمج Drift لمنع إعادة استخدام serial
    final now = DateTime.now();
    final oldOps = DataService.instance
        .getDeletedOperations()
        .where((o) => o.deletedAt != null && now.difference(o.deletedAt!).inDays > 30)
        .toList();
    for (final op in oldOps) {
      DataService.instance.permanentlyDeleteOperation(op.id);
    }
    // TODO: تنظيف العملاء القدامى عندما يصبح deletedAt متاحاً على MockCustomer
  }

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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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

  int _daysRemaining(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    final elapsed = DateTime.now().difference(deletedAt).inDays;
    final remaining = 30 - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  String _remainingText(int days) {
    if (days <= 0) return 'سيُحذف قريباً';
    if (days == 1) return 'متبقي: يوم واحد';
    if (days == 2) return 'متبقي: يومان';
    if (days <= 10) return 'متبقي: $days أيام';
    return 'متبقي: $days يوماً';
  }

  /// تاريخ حذف العميل تقديرياً = أحدث deletedAt بين عملياته المحذوفة.
  /// يرجع null إذا لم تكن له عمليات (لا يمكن معرفة تاريخ حذفه بدقة).
  DateTime? _customerDeletionDate(MockCustomer c) {
    DateTime? latest;
    for (final op in DataService.instance.getDeletedOperations()) {
      if (op.customerId == c.id && op.deletedAt != null) {
        if (latest == null || op.deletedAt!.isAfter(latest)) {
          latest = op.deletedAt;
        }
      }
    }
    return latest;
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
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
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _restoreCustomer(MockCustomer c) async {
    final confirmed = await _confirmDialog(
      title: 'استعادة العميل',
      message: 'هل تريد استعادة العميل "${c.primaryName}"؟',
      confirmLabel: 'استعادة',
      confirmColor: _green,
    );
    if (!confirmed || !mounted) return;
    final ok = DataService.instance.restoreCustomer(c.id);
    if (!mounted) return;
    if (ok) {
      _showSnack('تم استعادة العميل ${c.primaryName}', _green);
    } else {
      _showSnack('تعذّرت الاستعادة', _red);
    }
  }

  Future<void> _restoreOperation(Operation op) async {
    if (DataService.instance.getCustomerById(op.customerId) == null) {
      _showSnack('لا يمكن استعادة العملية حتى تستعيد العميل أولاً', _orange);
      return;
    }
    final confirmed = await _confirmDialog(
      title: 'استعادة العملية',
      message: 'هل تريد استعادة العملية ${op.serial}؟',
      confirmLabel: 'استعادة',
      confirmColor: _green,
    );
    if (!confirmed || !mounted) return;
    final ok = DataService.instance.restoreOperation(op.id);
    if (!mounted) return;
    if (ok) {
      _showSnack('تم استعادة العملية ${op.serial}', _green);
    } else {
      _showSnack('تعذّرت الاستعادة', _red);
    }
  }

  Future<void> _permanentlyDeleteCustomer(MockCustomer c) async {
    final confirmed = await _confirmDialog(
      title: 'حذف نهائي',
      message: 'سيتم حذف العميل "${c.primaryName}" وكل عملياته نهائياً.\nلا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف نهائي',
      confirmColor: _red,
    );
    if (!confirmed || !mounted) return;
    DataService.instance.permanentlyDeleteCustomer(c.id);
    if (!mounted) return;
    _showSnack('تم الحذف النهائي', _red);
  }

  Future<void> _permanentlyDeleteOperation(Operation op) async {
    final confirmed = await _confirmDialog(
      title: 'حذف نهائي',
      message: 'سيتم حذف العملية ${op.serial} نهائياً. لا يمكن التراجع.',
      confirmLabel: 'حذف نهائي',
      confirmColor: _red,
    );
    if (!confirmed || !mounted) return;
    DataService.instance.permanentlyDeleteOperation(op.id);
    if (!mounted) return;
    _showSnack('تم الحذف النهائي', _red);
  }

  Future<void> _deleteAll() async {
    final confirmed = await _confirmDialog(
      title: 'حذف كل السلة',
      message: 'سيتم حذف كل العناصر في السلة نهائياً. لا يمكن التراجع.',
      confirmLabel: 'حذف الكل',
      confirmColor: _red,
    );
    if (!confirmed || !mounted) return;
    final customers = DataService.instance.getDeletedCustomers().toList();
    final ops = DataService.instance.getDeletedOperations().toList();
    for (final c in customers) {
      DataService.instance.permanentlyDeleteCustomer(c.id);
    }
    for (final op in ops) {
      DataService.instance.permanentlyDeleteOperation(op.id);
    }
    if (!mounted) return;
    _showSnack('تم تفريغ السلة', _red);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kScaffoldBg,
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
            'سلة المحذوفات',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            ListenableBuilder(
              listenable: DataService.instance,
              builder: (context, _) {
                final hasItems = DataService.instance.getDeletedCustomers().isNotEmpty ||
                    DataService.instance.getDeletedOperations().isNotEmpty;
                if (!hasItems) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _deleteAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _red.withOpacity(0.35), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.delete_sweep, color: _red, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'حذف الكل',
                                style: TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: DataService.instance,
            builder: (context, _) {
              final deletedCustomers = DataService.instance.getDeletedCustomers();
              final deletedOps = DataService.instance.getDeletedOperations();
              if (deletedCustomers.isEmpty && deletedOps.isEmpty) {
                return _buildEmptyState();
              }
              return ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  if (deletedCustomers.isNotEmpty) ...[
                    _buildSectionHeader('العملاء المحذوفون', deletedCustomers.length),
                    ...deletedCustomers.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCustomerCard(c),
                    )),
                    const SizedBox(height: 8),
                  ],
                  if (deletedOps.isNotEmpty) ...[
                    _buildSectionHeader('العمليات المحذوفة', deletedOps.length),
                    ...deletedOps.map((op) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOperationCard(op),
                    )),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text('$count', style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(MockCustomer c) {
    final deletionDate = _customerDeletionDate(c);
    final daysLeft = deletionDate != null ? _daysRemaining(deletionDate) : 30;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  c.primaryName.isNotEmpty ? c.primaryName[0] : '?',
                  style: const TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.primaryName, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (c.aliases.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(c.aliases.join('، '), style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, color: _orange, size: 14),
              const SizedBox(width: 4),
              Text('تاريخ الحذف: ${_formatDate(deletionDate)}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const Spacer(),
              if (deletionDate != null)
                Text(_remainingText(daysLeft), style: const TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildActionButton(label: 'استعادة', color: _green, icon: Icons.restore, onTap: () => _restoreCustomer(c))),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton(label: 'حذف نهائي', color: _red, icon: Icons.delete_forever, onTap: () => _permanentlyDeleteCustomer(c))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(Operation op) {
    final daysLeft = _daysRemaining(op.deletedAt);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(op.customerName, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('|', style: TextStyle(color: kTextSecondary.withOpacity(0.5), fontSize: 12)),
              const SizedBox(width: 8),
              Text(op.serial, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: _orange, size: 14),
              const SizedBox(width: 4),
              Text('تاريخ الحذف: ${_formatDate(op.deletedAt)}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const Spacer(),
              Text(_remainingText(daysLeft), style: const TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildActionButton(label: 'استعادة', color: _green, icon: Icons.restore, onTap: () => _restoreOperation(op))),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton(label: 'حذف نهائي', color: _red, icon: Icons.delete_forever, onTap: () => _permanentlyDeleteOperation(op))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: kTextSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('سلة المحذوفات فارغة', style: TextStyle(color: kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}