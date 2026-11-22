import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';
import '../widgets/animated_list_item.dart';
import 'add_customer_screen.dart';

class CustomerSelectionResult {
  final String id;
  final bool isNew;
  const CustomerSelectionResult({required this.id, this.isNew = false});
}

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
      Navigator.pop(context, CustomerSelectionResult(id: newCustomer.id, isNew: true));
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
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
            final customers = DataService.instance.searchCustomersByRecency(_searchQuery);
            return Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    decoration: _neumorphicDecoration(radius: 12),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن عميل...',
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
                      ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: kTextSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return AnimatedListItem(
                              index: index,
                              child: _buildCustomerCard(customers[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
          child: _buildAddCustomerButton(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildAddCustomerButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton.icon(
        onPressed: _openAddCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
        ),
        icon: const Icon(Icons.person_add, size: 22),
        label: const Text('إضافة عميل جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCustomerCard(MockCustomer customer) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, CustomerSelectionResult(id: customer.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: _neumorphicDecoration(radius: 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(customer.primaryName.characters.first, style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.primaryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (customer.aliases.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          customer.aliases.join('، '),
                          style: const TextStyle(color: kTextSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (customer.isVip)
                const Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}