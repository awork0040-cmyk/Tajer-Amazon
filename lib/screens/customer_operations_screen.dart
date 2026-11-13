import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';

const Color _kOrange = Color(0xFFF0883E);
const Color _kGreen = Color(0xFF3FB950);
const Color _kDanger = Color(0xFFE53935);

class CustomerOperationsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerOperationsScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<CustomerOperationsScreen> createState() => _CustomerOperationsScreenState();
}

class _CustomerOperationsScreenState extends State<CustomerOperationsScreen> {
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

  Color _statusColor(OperationStatus s) {
    switch (s) {
      case OperationStatus.unconfirmed: return _kOrange;
      case OperationStatus.confirmed: return _kGreen;
      case OperationStatus.delivered: return kTextSecondary;
      case OperationStatus.deleted: return _kDanger;
    }
  }

  String _statusLabel(OperationStatus s) {
    switch (s) {
      case OperationStatus.unconfirmed: return 'غير مؤكدة';
      case OperationStatus.confirmed: return 'مؤكدة';
      case OperationStatus.delivered: return 'تم التوصيل';
      case OperationStatus.deleted: return 'محذوفة';
    }
  }

  Future<void> _openScanner() async {
    final unconfirmed = DataService.instance
        .getOperationsForCustomer(widget.customerId)
        .where((o) => o.status == OperationStatus.unconfirmed)
        .toList();

    if (unconfirmed.isEmpty) {
      _showSnack('لا توجد عمليات غير مؤكدة لهذا العميل', _kOrange);
      return;
    }

    final scannedOp = await Navigator.push<Operation>(
      context,
      MaterialPageRoute(
        builder: (_) => _MockScannerScreen(
          customerName: widget.customerName,
          unconfirmedOps: unconfirmed,
        ),
      ),
    );

    if (scannedOp != null && mounted) {
      DataService.instance.updateOperationStatus(scannedOp.id, OperationStatus.confirmed);
      _showSnack('تم تأكيد العملية ${scannedOp.serial}', _kGreen);
    }
  }

  void _showOperationOptions(Operation op) {
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(op.serial, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.normal)),
              const SizedBox(height: 12),
              if (op.status == OperationStatus.unconfirmed)
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: kPrimary),
                  title: const Text('تأكيد (عبر المسح بالكاميرا)', style: TextStyle(color: kPrimary, fontWeight: FontWeight.normal)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openScanner();
                  },
                ),
              if (op.status == OperationStatus.confirmed)
                ListTile(
                  leading: const Icon(Icons.undo, color: _kOrange),
                  title: const Text('إلغاء التأكيد', style: TextStyle(color: _kOrange, fontWeight: FontWeight.normal)),
                  onTap: () {
                    Navigator.pop(ctx);
                    DataService.instance.updateOperationStatus(op.id, OperationStatus.unconfirmed);
                    _showSnack('تم إلغاء تأكيد العملية', _kOrange);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.print, color: kPrimary),
                title: const Text('إعادة طباعة', style: TextStyle(color: kPrimary, fontWeight: FontWeight.normal)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSnack('إعادة الطباعة ستُبرمج لاحقاً', kPrimaryDark);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: kPrimary),
                title: const Text('نسخ التسلسل', style: TextStyle(color: kPrimary, fontWeight: FontWeight.normal)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: op.serial));
                  Navigator.pop(ctx);
                  _showSnack('تم نسخ التسلسل', kPrimaryDark);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _kDanger),
                title: const Text('حذف', style: TextStyle(color: _kDanger, fontWeight: FontWeight.normal)),
                onTap: () {
                  Navigator.pop(ctx);
                  DataService.instance.deleteOperation(op.id);
                  _showSnack('تم نقل العملية لسلة المحذوفات', _kDanger);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final customer = DataService.instance.getCustomerById(widget.customerId);
          if (customer == null) {
            return const Scaffold(
              backgroundColor: kScaffoldBg,
              body: Center(child: Text('العميل غير موجود', style: TextStyle(color: kTextSecondary))),
            );
          }

          // فقط غير المؤكدة + المؤكدة (المُوصَّلة لا تظهر هنا)
          final ops = DataService.instance
              .getDisplayableOperationsForCustomer(widget.customerId);

          ops.sort((a, b) {
            int priority(OperationStatus s) {
              if (s == OperationStatus.unconfirmed) return 0;
              return 1;
            }
            final p = priority(a.status).compareTo(priority(b.status));
            if (p != 0) return p;
            return b.createdAt.compareTo(a.createdAt);
          });

          final unconfirmedCount = ops.where((o) => o.status == OperationStatus.unconfirmed).length;
          final confirmedCount = ops.where((o) => o.status == OperationStatus.confirmed).length;
          final totalAmount = ops.fold<int>(0, (sum, o) => sum + o.amount);

          return Scaffold(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('غير مؤكدة', '$unconfirmedCount', _kOrange),
                          Container(width: 1, height: 30, color: Colors.white12),
                          _buildStatItem('مؤكدة', '$confirmedCount', _kGreen),
                          Container(width: 1, height: 30, color: Colors.white12),
                          _buildStatItem('المعلّق', _formatAmount(totalAmount), kTextPrimary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner, size: 20, color: kPrimary),
                        label: const Text('مسح مخصص', style: TextStyle(color: kPrimary, fontWeight: FontWeight.normal, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C2733),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ops.isEmpty
                        ? const Center(child: Text('لا توجد عمليات معلّقة', style: TextStyle(color: kTextSecondary, fontSize: 14)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: ops.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final op = ops[index];
                              return _AnimatedItem(
                                key: ValueKey('op_${op.id}_$index'),
                                index: index,
                                child: _buildOperationCard(op),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showOperationOptions(op),
        onTap: () {},
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
                          Text(op.serial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(_statusLabel(op.status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
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
    );
  }
}

class _AnimatedItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedItem({Key? key, required this.index, required this.child}) : super(key: key);

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _MockScannerScreen extends StatelessWidget {
  final String customerName;
  final List<Operation> unconfirmedOps;

  const _MockScannerScreen({
    required this.customerName,
    required this.unconfirmedOps,
  });

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('مسح عمليات $customerName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Icon(Icons.qr_code_scanner, color: Colors.white12, size: 120),
              ),
            ),
            Center(
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unconfirmedOps.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'لا توجد عمليات غير مؤكدة',
                        style: TextStyle(color: kTextPrimary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(unconfirmedOps.first.serial, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_formatAmount(unconfirmedOps.first.amount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          const Text('وجّه الكاميرا نحو رمز QR', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, unconfirmedOps.first);
                        },
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                        label: const Text(
                          'محاكاة مسح QR',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}