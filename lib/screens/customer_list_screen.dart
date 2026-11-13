import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/animated_list_item.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';
import 'add_customer_screen.dart';
import 'customer_profile_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterType = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.people, color: _filterType == 0 ? kPrimary : kTextSecondary),
                title: Text('الكل', style: TextStyle(color: _filterType == 0 ? kPrimary : kTextPrimary)),
                onTap: () { setState(() => _filterType = 0); Navigator.pop(context); },
              ),
              ListTile(
                leading: Icon(Icons.star, color: _filterType == 1 ? Colors.amber : kTextSecondary),
                title: Text('المميزون', style: TextStyle(color: _filterType == 1 ? Colors.amber : kTextPrimary)),
                onTap: () { setState(() => _filterType = 1); Navigator.pop(context); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddCustomer() async {
    final newCustomer = await Navigator.push<MockCustomer>(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen(isFullVersion: true)),
    );
    if (newCustomer != null) {
      DataService.instance.addCustomer(newCustomer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة العميل ${newCustomer.primaryName}'),
          backgroundColor: Colors.green,
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

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// ترتيب MRU: الأحدث شراءً أولاً، ثم الجدد حسب ترتيب الإضافة.
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
          title: const Text('العملاء المعتمدون', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [IconButton(icon: const Icon(Icons.filter_list, color: kPrimary), onPressed: _showFilterSheet)],
        ),
        body: ListenableBuilder(
          listenable: DataService.instance,
          builder: (context, _) {
            final customers = _sortByRecency(
              DataService.instance.searchCustomers(_searchQuery, onlyVip: _filterType == 1),
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
                        hintText: 'ابحث بالاسم أو الهاتف...',
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
                      ? Center(child: Text(_searchQuery.isEmpty ? 'لا يوجد عملاء بعد.' : 'لا توجد نتائج. جرّب كلمة بحث أخرى.', style: const TextStyle(color: kTextSecondary, fontSize: 14)))
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
    final bgColor = customer.isVip ? Colors.amber.withOpacity(0.1) : kSurfaceColor;
    final borderColor = customer.isVip ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05);
    final needsPhoneAlert = (customer.primaryPhone == null || customer.primaryPhone!.isEmpty) && customer.pendingAmount >= 25000;

    return AnimatedListItem(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerProfileScreen(customerId: customer.id))),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
            ),
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
                          const SizedBox(height: 4),
                          Text('${customer.totalOps} عمليات — ${_formatAmount(customer.totalAmount)} د.ع', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                        ],
                      ),
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