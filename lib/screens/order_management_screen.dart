import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import '../widgets/animated_list_item.dart';
import 'customer_operations_screen.dart' as cust_ops;
import 'customer_profile_screen.dart';

const Color kOrange = Color(0xFFF0883E);
const Color kGreen = Color(0xFF3FB950);
const Color kGray = Color(0xFF8B949E);
const Color kMutedOrange = Color(0xFFC26A2D);
const Color kMutedGreen = Color(0xFF348A4A);
const Color kDanger = Color(0xFFE53935);

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);
  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
            width: 48, height: 48,
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

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
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

  void _onWhatsAppTap(String customerId) {
    final c = DataService.instance.getCustomerById(customerId);
    if (c == null) {
      _showSnack('العميل غير موجود', kDanger);
      return;
    }
    if (c.primaryPhone == null || c.primaryPhone!.isEmpty) {
      _showSnack('لا يوجد رقم هاتف لهذا العميل', kOrange);
      return;
    }
    _showSnack('فتح واتساب مع ${c.primaryName} — سيُفعّل بعد تثبيت url_launcher', kPrimary);
  }

  void _onDeliverTap(String customerId, String customerName) {
    final confirmedOps = DataService.instance
        .getOperationsForCustomer(customerId)
        .where((o) => o.status == OperationStatus.confirmed)
        .toList();

    if (confirmedOps.isEmpty) {
      _showSnack('لا توجد عمليات مؤكدة لهذا العميل', kOrange);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'تأكيد التوصيل',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد أنك سلمت بضاعة العميل ($customerName)؟\n${confirmedOps.length} عمليات ستنتقل إلى "تم التوصيل".',
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
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    for (final op in confirmedOps) {
                      DataService.instance.updateOperationStatus(op.id, OperationStatus.delivered);
                    }
                    _showSnack('تم تسليم بضاعة $customerName', kGreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══ Bottom Sheet الجديد ═══
  void _onLongPressCustomer(String customerId, String customerName, List<Operation> ops) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                customerName,
                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
              ),
              Text(
                '${ops.length} عمليات',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.05), height: 1, thickness: 1),
              ListTile(
                leading: const Icon(Icons.person, color: kPrimary),
                title: const Text(
                  'فتح ملف العميل',
                  style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerProfileScreen(customerId: customerId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: kDanger),
                title: const Text(
                  'حذف العمليات',
                  style: TextStyle(color: kDanger, fontWeight: FontWeight.normal),
                ),
                subtitle: const Text(
                  'ستذهب لسلة المحذوفات',
                  style: TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteOps(ops, customerName);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteOps(List<Operation> ops, String customerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'حذف العمليات',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'سيتم حذف ${ops.length} عمليات للعميل ($customerName).\nيمكن استعادتها خلال 30 يوماً من السلة.',
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
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteOpsWithUndo(ops);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'حذف',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteOpsWithUndo(List<Operation> ops) {
    final opIds = ops.map((o) => o.id).toList();
    for (final id in opIds) {
      DataService.instance.deleteOperation(id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف ${ops.length} عمليات'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'استعادة',
          textColor: Colors.white,
          onPressed: () {
            for (final id in opIds) {
              DataService.instance.restoreOperation(id);
            }
          },
        ),
      ),
    );
  }

  void _showDeliveredBatchSheet(Map<String, dynamic> group) {
    final ops = group['ops'] as List<Operation>;
    final name = group['name'] as String;
    final d = group['date'] as DateTime;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تفاصيل دفعة $name',
                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
              ),
              Text(
                'التاريخ: $dateStr',
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ops.length,
                  itemBuilder: (context, index) {
                    final op = ops[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        op.serial,
                        style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.normal),
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: Text(
                        '${_formatAmount(op.amount)} د.ع',
                        style: const TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.check, color: kGreen, size: 20),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDeliveredLongPress(Map<String, dynamic> group) {
    final ops = group['ops'] as List<Operation>;
    final name = group['name'] as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.undo, color: kPrimary),
                title: const Text(
                  'إلغاء التوصيل (إرجاع لمؤكدة)',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  for (final op in ops) {
                    DataService.instance.updateOperationStatus(op.id, OperationStatus.confirmed);
                  }
                  _showSnack('تم إرجاع العمليات لتبويب مؤكدة', kPrimary);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: kDanger),
                title: const Text(
                  'حذف العمليات',
                  style: TextStyle(color: kDanger, fontWeight: FontWeight.normal),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteOpsWithUndo(ops);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActiveColor() {
    if (_currentTab == 0) return kOrange;
    if (_currentTab == 1) return kGreen;
    return kGray;
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
            'إدارة الطلبات',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: ListenableBuilder(
          listenable: DataService.instance,
          builder: (context, _) {
            final unconfirmed = DataService.instance.getUnconfirmedOperations();
            final confirmed = DataService.instance.getConfirmedOperations();
            final delivered = DataService.instance.getDeliveredOperations();
            final currentOps = _currentTab == 0
                ? unconfirmed
                : _currentTab == 1
                    ? confirmed
                    : delivered;
            final filteredOps = _searchQuery.isEmpty
                ? currentOps
                : currentOps
                    .where((o) => DataService.instance
                        .normalizeArabic(o.customerName)
                        .contains(DataService.instance.normalizeArabic(_searchQuery)))
                    .toList();

            final grouped = _groupByCustomer(filteredOps);
            final totalAmount = filteredOps.fold<int>(0, (sum, o) => sum + o.amount);

            return Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildSlidingTabsBar(),
                ),
                const SizedBox(height: 10),
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
                        _buildStatItem('العمليات', '${filteredOps.length}'),
                        Container(width: 1, height: 20, color: Colors.white12),
                        _buildStatItem('المبلغ', _formatAmount(totalAmount)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    decoration: _neumorphicDecoration(),
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
                                icon: const Icon(Icons.close, color: kTextSecondary, size: 16),
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
                ),
                const SizedBox(height: 10),
                if (_currentTab == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSnack('شاشة المسح الجماعي ستُبرمج لاحقاً', kPrimaryDark),
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white70),
                        label: const Text(
                          'مسح جماعي',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.normal, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C2733),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                if (_currentTab == 0) const SizedBox(height: 10),
                Expanded(
                  child: _currentTab == 2
                      ? _buildDeliveredList(delivered, _searchQuery)
                      : _buildOrdersList(grouped, isConfirmed: _currentTab == 1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, List<Operation>> _groupByCustomer(List<Operation> ops) {
    final map = <String, List<Operation>>{};
    for (final op in ops) {
      map.putIfAbsent(op.customerId, () => []).add(op);
    }
    return map;
  }

  Widget _buildSlidingTabsBar() {
    final activeColor = _getActiveColor();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double tabWidth = w / 3;
        final double indicatorWidth = tabWidth - 8;
        double leftPos;
        if (_currentTab == 0) {
          leftPos = (2 * tabWidth) + 4;
        } else if (_currentTab == 1) {
          leftPos = tabWidth + 4;
        } else {
          leftPos = 4;
        }

        return Container(
          height: 52,
          decoration: _neumorphicDecoration(radius: 12),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: leftPos,
                top: 4,
                bottom: 4,
                width: indicatorWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _buildTabButton('غير مؤكدة', 0, kOrange),
                    _buildTabButton('مؤكدة', 1, kGreen),
                    _buildTabButton('تم التوصيل', 2, kGray),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String title, int index, Color activeColor) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_currentTab != index) {
            setState(() {
              _currentTab = index;
              _searchController.clear();
              _searchQuery = '';
            });
          }
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: isActive ? activeColor : kTextSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
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
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOrdersList(Map<String, List<Operation>> grouped, {required bool isConfirmed}) {
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          isConfirmed ? 'لا توجد طلبات مؤكدة' : 'لا توجد طلبات غير مؤكدة',
          style: const TextStyle(color: kTextSecondary, fontSize: 14),
        ),
      );
    }

    // ترتيب البطاقات حسب أحدث عملية لكل عميل
    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aMax = a.value.map((o) => o.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
      final bMax = b.value.map((o) => o.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
      return bMax.compareTo(aMax);
    });

    final color = isConfirmed ? kMutedGreen : kMutedOrange;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final ops = entry.value;
        final customerName = ops.first.customerName;
        final total = ops.fold<int>(0, (sum, o) => sum + o.amount);

        return AnimatedListItem(
          key: ValueKey('tab${_currentTab}_cust${entry.key}'),
          index: index,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (!isConfirmed) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => cust_ops.CustomerOperationsScreen(
                        customerId: entry.key,
                        customerName: customerName,
                      ),
                    ),
                  );
                }
              },
              onLongPress: () => _onLongPressCustomer(entry.key, customerName, ops),
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
                          Text(
                            customerName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ops.length} عمليات — ${_formatAmount(total)} د.ع',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (isConfirmed) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // زر "وصل" — مخفف (نص فقط بدون حدود)
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => _onWhatsAppTap(entry.key),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kPrimary.withOpacity(0.75),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      'وصل',
                                      style: TextStyle(
                                        color: kPrimary.withOpacity(0.75),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // زر "تم التوصيل" — مخفف (خلفية شفافة + حدود)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _onDeliverTap(entry.key, customerName),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: kPrimary.withOpacity(0.12),
                                      side: BorderSide(color: kPrimary.withOpacity(0.35), width: 1),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'تم التوصيل',
                                      style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Container(width: 6, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveredList(List<Operation> delivered, String query) {
    final groups = <String, Map<String, dynamic>>{};
    for (final op in delivered) {
      if (op.deliveredAt == null) continue;
      if (query.isNotEmpty &&
          !DataService.instance
              .normalizeArabic(op.customerName)
              .contains(DataService.instance.normalizeArabic(query))) {
        continue;
      }
      final d = op.deliveredAt!;
      final keyStr = '${op.customerId}_${d.year}-${d.month}-${d.day}';
      if (!groups.containsKey(keyStr)) {
        groups[keyStr] = {
          'key': keyStr,
          'name': op.customerName,
          'date': d,
          'count': 0,
          'amount': 0,
          'ops': <Operation>[],
        };
      }
      groups[keyStr]!['count'] = (groups[keyStr]!['count'] as int) + 1;
      groups[keyStr]!['amount'] = (groups[keyStr]!['amount'] as int) + op.amount;
      (groups[keyStr]!['ops'] as List<Operation>).add(op);
    }
    if (groups.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات تم توصيلها', style: TextStyle(color: kTextSecondary, fontSize: 14)),
      );
    }

    // ترتيب المجموعات حسب تاريخ التوصيل (الأحدث أولاً)
    final list = groups.values.toList();
    list.sort((a, b) {
      final da = a['date'] as DateTime;
      final db = b['date'] as DateTime;
      return db.compareTo(da);
    });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final g = list[index];
        final d = g['date'] as DateTime;
        final dateStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        return AnimatedListItem(
          key: ValueKey('delivered_${g['key']}'),
          index: index,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDeliveredBatchSheet(g),
              onLongPress: () => _onDeliveredLongPress(g),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  g['name'] as String,
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${g['count']} عمليات — ${_formatAmount(g['amount'] as int)} د.ع',
                                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(color: kTextSecondary, fontSize: 12),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Container(width: 6, color: kGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}