import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/animated_list_item.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';
import 'add_customer_screen.dart';

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddCustomer() async {
    final newCustomer = await Navigator.push<MockCustomer>(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen(isFullVersion: false)),
    );
    if (newCustomer != null) {
      DataService.instance.addCustomer(newCustomer);
      if (!mounted) return;
      Navigator.pop(context, newCustomer.primaryName);
    }
  }

  void _showAddPhoneDialog(MockCustomer customer) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إضافة رقم هاتف', style: TextStyle(color: kTextPrimary, fontSize: 16)),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(hintText: '07XX XXX XXXX', hintStyle: TextStyle(color: kTextSecondary)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              Navigator.pop(ctx);
              if (phone.isNotEmpty) {
                DataService.instance.updateCustomer(customer.copyWith(primaryPhone: phone));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('تم حفظ الرقم'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                );
              }
            },
            child: const Text('حفظ', style: TextStyle(color: kPrimary)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
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

  /// يرتب العملاء حسب MRU (آخر شراء أولاً)، ثم الجدد حسب ترتيب الإضافة.
  List<MockCustomer> _sortByRecency(List<MockCustomer> list) {
    final sorted = List<MockCustomer>.from(list);
    sorted.sort((a, b) {
      if (a.lastUsedAt != null && b.lastUsedAt != null) {
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      }
      if (a.lastUsedAt != null && b.lastUsedAt == null) return -1;
      if (a.lastUsedAt == null && b.lastUsedAt != null) return 1;
      final na = int.tryParse(a.id.replaceFirst('c', '')) ?? 0;
      final nb = int.tryParse(b.id.replaceFirst('c', '')) ?? 0;
      return na.compareTo(nb);
    });
    return sorted;
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
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1C2733), border: Border.all(color: Colors.white12)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          title: const Text('اختيار عميل', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: ListenableBuilder(
          listenable: DataService.instance,
          builder: (context, _) {
            final customers = _sortByRecency(
              DataService.instance.searchCustomers(_searchQuery),
            );
            return Column(
              children: [
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
                        suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                          icon: const Icon(Icons.close, color: kTextSecondary, size: 16),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: customers.isEmpty
                      ? const Center(child: Text('لا توجد نتائج. جرّب كلمة بحث أخرى.', style: TextStyle(color: kTextSecondary, fontSize: 14)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildCustomerCard(customers[index], index),
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24.0, left: 16.0),
          child: FloatingActionButton(
            onPressed: _openAddCustomer,
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.person_add),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(MockCustomer customer, int index) {
    final needsPhoneAlert = (customer.primaryPhone == null || customer.primaryPhone!.isEmpty) && customer.pendingAmount >= 25000;

    return AnimatedListItem(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, customer.primaryName),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _neumorphicDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(customer.primaryName.characters.first, style: const TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.primaryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (customer.aliases.isNotEmpty)
                            Text(customer.aliases.join('، '), style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                          if (customer.pendingOps > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${customer.pendingOps} عمليات — ${_formatAmount(customer.pendingAmount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                    if (needsPhoneAlert)
                      TextButton(
                        onPressed: () => _showAddPhoneDialog(customer),
                        style: TextButton.styleFrom(
                          backgroundColor: kPrimary.withOpacity(0.15),
                          foregroundColor: kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('أضف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
                if (needsPhoneAlert)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'تنبيه: أضف رقم الهاتف — مبيعاته تجاوزت (25,000 د.ع)',
                      style: TextStyle(color: const Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}