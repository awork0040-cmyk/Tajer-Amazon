import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import 'add_customer_screen.dart';
import 'customer_history_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;
  const CustomerProfileScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  static const Color _kGold = Color(0xFFFFC107);
  static const Color _kRed = Color(0xFFE53935);
  static const double _gap = 14;
  static const double _pad = 18;

  Future<void> _openEditScreen(MockCustomer customer) async {
    final updated = await Navigator.push<MockCustomer>(
      context,
      MaterialPageRoute(builder: (_) => AddCustomerScreen(customerToEdit: customer, isFullVersion: true)),
    );
    if (updated != null) DataService.instance.updateCustomer(updated);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
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

  void _toggleVip() {
    DataService.instance.toggleVip(widget.customerId);
  }

  void _showDeleteDialog(MockCustomer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف العميل', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('هل أنت متأكد من حذف العميل (${customer.primaryName})؟\nسيتم نقله مع جميع عملياته إلى سلة المحذوفات.', style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
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
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kRed, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
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
            return const Scaffold(backgroundColor: kScaffoldBg, body: Center(child: Text('العميل غير موجود', style: TextStyle(color: kTextSecondary))));
          }

          final delivered = DataService.instance.getOperationsForCustomer(customer.id)
              .where((o) => o.status == OperationStatus.delivered).toList();
          final deliveredCount = delivered.length;
          final deliveredTotal = delivered.fold<int>(0, (s, o) => s + o.amount);

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              title: const SizedBox.shrink(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: kPrimary, size: 22),
                    tooltip: 'تعديل البيانات',
                    onPressed: () => _openEditScreen(customer),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // ═══ 1. الإحصائيات (تم التوصيل) ═══
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('العمليات المكتملة', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text('$deliveredCount', style: const TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 46, color: Colors.white12),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('الإجمالي', style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text('${_formatAmount(deliveredTotal)} د.ع', style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gap),

                  // ═══ 2. بطاقة المعلومات ═══
                  Container(
                    padding: const EdgeInsets.all(_pad),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الاسم
                        Row(
                          children: [
                            Expanded(
                              child: Text(customer.primaryName, style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            if (customer.isVip)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _kGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _kGold.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: _kGold, size: 14),
                                    SizedBox(width: 4),
                                    Text('VIP', style: TextStyle(color: _kGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // الأسماء البديلة
                        if (customer.aliases.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: customer.aliases.map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(a, style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Container(height: 1, color: Colors.white.withOpacity(0.06)),
                        const SizedBox(height: 16),

                        // الهاتف
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'رقم الهاتف',
                          value: (customer.primaryPhone != null && customer.primaryPhone!.isNotEmpty)
                              ? customer.primaryPhone!
                              : 'غير محدد',
                          isEmpty: customer.primaryPhone == null || customer.primaryPhone!.isEmpty,
                          isLtr: true,
                        ),

                        // الأرقام الثانوية
                        if (customer.secondaryPhones.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildInfoRow(
                            icon: Icons.phone_android_outlined,
                            label: customer.secondaryPhones.length > 1 ? 'أرقام إضافية' : 'رقم إضافي',
                            value: customer.secondaryPhones.join('  •  '),
                            isEmpty: false,
                            isLtr: true,
                          ),
                        ],

                        // العنوان
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'العنوان',
                          value: (customer.address != null && customer.address!.isNotEmpty) ? customer.address! : 'غير محدد',
                          isEmpty: customer.address == null || customer.address!.isEmpty,
                        ),

                        // الملاحظات
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          icon: Icons.notes_outlined,
                          label: 'الملاحظات',
                          value: (customer.notes != null && customer.notes!.isNotEmpty) ? customer.notes! : 'لا توجد ملاحظات',
                          isEmpty: customer.notes == null || customer.notes!.isEmpty,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gap),

                  // ═══ 3. زر VIP ═══
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _toggleVip,
                      icon: Icon(customer.isVip ? Icons.star : Icons.star_border, color: _kGold, size: 22),
                      label: Text(
                        customer.isVip ? 'إزالة تمييز VIP' : 'تمييز كعميل VIP',
                        style: const TextStyle(color: _kGold, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _kGold.withOpacity(customer.isVip ? 0.15 : 0.08),
                        side: BorderSide(color: _kGold.withOpacity(customer.isVip ? 0.8 : 0.4), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: _gap),

                  // ═══ 4. بطاقة السجل ═══
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CustomerHistoryScreen(customerId: customer.id, customerName: customer.primaryName),
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(_pad),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.history, color: kPrimary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('السجل', style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 3),
                                  Text('عرض العمليات المكتملة', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_left, color: kTextSecondary, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: _gap),

                  // ═══ 5. زر حذف العميل ═══
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(customer),
                      icon: const Icon(Icons.delete_outline, color: _kRed, size: 20),
                      label: const Text('حذف العميل', style: TextStyle(color: _kRed, fontSize: 15, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _kRed.withOpacity(0.1),
                        side: BorderSide(color: _kRed.withOpacity(0.35), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEmpty,
    bool isLtr = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kTextSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isEmpty ? kTextSecondary.withOpacity(0.6) : kTextPrimary,
                  fontSize: 14,
                  fontWeight: isEmpty ? FontWeight.normal : FontWeight.w600,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
                textDirection: isLtr ? TextDirection.ltr : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}