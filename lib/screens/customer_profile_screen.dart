import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/animated_list_item.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import 'add_customer_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;
  const CustomerProfileScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Future<void> _openEditScreen(MockCustomer customer) async {
    final updated = await Navigator.push<MockCustomer>(
      context,
      MaterialPageRoute(builder: (_) => AddCustomerScreen(customerToEdit: customer, isFullVersion: true)),
    );
    if (updated != null) {
      DataService.instance.updateCustomer(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بيانات العميل بنجاح'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
      );
    }
  }

  void _toggleVip() {
    DataService.instance.toggleVip(widget.customerId);
    final c = DataService.instance.getCustomerById(widget.customerId);
    if (c != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(c.isVip ? 'تم تمييز العميل كـ VIP' : 'تم إزالة تمييز VIP'),
          backgroundColor: c.isVip ? Colors.amber : kTextSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
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

  void _showDeleteDialog(MockCustomer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف العميل', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          'هل أنت متأكد من حذف العميل (${customer.primaryName})؟\nسيتم نقله مع جميع عملياته إلى سلة المحذوفات لمدة 30 يوماً.',
          style: const TextStyle(color: kTextSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    DataService.instance.deleteCustomer(customer.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نقل العميل لسلة المحذوفات'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(OperationStatus s) {
    switch (s) {
      case OperationStatus.unconfirmed: return const Color(0xFFF0883E);
      case OperationStatus.confirmed: return const Color(0xFF3FB950);
      case OperationStatus.delivered: return kTextSecondary;
      case OperationStatus.deleted: return Colors.red;
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

  Widget _buildOperationRow(Operation op) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(op.serial, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(op.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _statusColor(op.status).withOpacity(0.3)),
            ),
            child: Text(_statusLabel(op.status), style: TextStyle(color: _statusColor(op.status), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
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
          final customerOps = DataService.instance.getOperationsForCustomer(customer.id);
          customerOps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              toolbarHeight: 70,
              leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              title: Text(customer.primaryName, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              actions: [
                IconButton(icon: const Icon(Icons.edit, color: kPrimary, size: 22), onPressed: () => _openEditScreen(customer)),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  AnimatedListItem(
                    index: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: _neumorphicDecoration(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('عدد العمليات', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('${customer.totalOps}', style: const TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('المبلغ الإجمالي', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('${_formatAmount(customer.totalAmount)} د.ع', style: const TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (customerOps.isNotEmpty)
                    AnimatedListItem(
                      index: 1,
                      child: _buildInfoCard(
                        title: 'العمليات (${customerOps.length})',
                        icon: Icons.list_alt,
                        children: customerOps.map(_buildOperationRow).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (customer.primaryPhone != null || customer.secondaryPhones.isNotEmpty || customer.address != null)
                    AnimatedListItem(
                      index: 2,
                      child: _buildInfoCard(
                        title: 'معلومات الاتصال',
                        icon: Icons.contact_phone,
                        children: [
                          if (customer.primaryPhone != null) _buildInfoRow('الهاتف الأساسي', customer.primaryPhone!),
                          if (customer.secondaryPhones.isNotEmpty) _buildInfoRow('الهواتف الثانوية', customer.secondaryPhones.join('، ')),
                          if (customer.address != null) _buildInfoRow('العنوان', customer.address!),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (customer.aliases.isNotEmpty)
                    AnimatedListItem(
                      index: 3,
                      child: _buildInfoCard(
                        title: 'الأسماء البديلة',
                        icon: Icons.badge,
                        children: [
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: customer.aliases.map((name) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.3))),
                              child: Text(name, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (customer.notes != null && customer.notes!.isNotEmpty)
                    AnimatedListItem(
                      index: 4,
                      child: _buildInfoCard(
                        title: 'الملاحظات',
                        icon: Icons.notes,
                        children: [Text(customer.notes!, style: const TextStyle(color: kTextPrimary, fontSize: 14, height: 1.5))],
                      ),
                    ),
                  const SizedBox(height: 30),
                  AnimatedListItem(
                    index: 5,
                    child: SizedBox(
                      height: 55,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _toggleVip,
                          child: Container(
                            decoration: BoxDecoration(
                              color: customer.isVip ? Colors.amber.withOpacity(0.15) : kSurfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: customer.isVip ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.05), width: 1.5),
                              boxShadow: [BoxShadow(color: customer.isVip ? Colors.amber.withOpacity(0.2) : Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(customer.isVip ? Icons.star : Icons.star_border, color: customer.isVip ? Colors.amber : kTextSecondary, size: 26),
                                const SizedBox(width: 8),
                                Text(customer.isVip ? 'إزالة تمييز VIP' : 'تمييز كعميل VIP', style: TextStyle(color: customer.isVip ? Colors.amber : kTextSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedListItem(
                    index: 6,
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => _showDeleteDialog(customer),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.15),
                          side: BorderSide(color: Colors.red.withOpacity(0.35), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('حذف العميل', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: kTextSecondary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}