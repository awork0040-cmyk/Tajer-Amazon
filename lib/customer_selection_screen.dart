import 'package:flutter/material.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kPrimaryDark = Color(0xFF1565C0);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

class MockCustomer {
  final String id;
  final String primaryName;
  final String? alias;
  final String? phone;
  final int pendingOpsCount;
  final int pendingAmount;

  MockCustomer({
    required this.id,
    required this.primaryName,
    this.alias,
    this.phone,
    this.pendingOpsCount = 0,
    this.pendingAmount = 0,
  });
}

final List<MockCustomer> _mockCustomers = [
  MockCustomer(id: '1', primaryName: 'أحمد علي', alias: 'أبو علي', phone: '07801234567', pendingOpsCount: 6, pendingAmount: 75000),
  MockCustomer(id: '2', primaryName: 'حميدة سالم', pendingOpsCount: 2, pendingAmount: 30000),
  MockCustomer(id: '3', primaryName: 'محمد كريم', alias: 'محمد', phone: '07709876543', pendingOpsCount: 1, pendingAmount: 15000),
  MockCustomer(id: '4', primaryName: 'زينب حسن', alias: 'أم حسين', pendingOpsCount: 10, pendingAmount: 120000),
  MockCustomer(id: '5', primaryName: 'علي جاسم', pendingOpsCount: 3, pendingAmount: 22000),
  MockCustomer(id: '6', primaryName: 'فاطمة عبد', alias: 'فطوم', phone: '07811112222', pendingOpsCount: 0, pendingAmount: 0),
];

String normalizeArabic(String input) {
  if (input.isEmpty) return '';
  String s = input.trim();
  s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  s = s.replaceAll(RegExp('[إأآا]'), 'ا');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll('ة', 'ه');
  s = s.replaceAll('ؤ', 'و');
  s = s.replaceAll('ئ', 'ي');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.toLowerCase();
}

class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({Key? key, required this.index, required this.child}) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
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

  List<MockCustomer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _mockCustomers.take(30).toList();
    final normalizedQuery = normalizeArabic(_searchQuery);
    return _mockCustomers.where((c) {
      final normPrimary = normalizeArabic(c.primaryName);
      final normAlias = c.alias != null ? normalizeArabic(c.alias!) : '';
      final phone = c.phone ?? '';
      return normPrimary.contains(normalizedQuery) ||
          normAlias.contains(normalizedQuery) ||
          phone.contains(_searchQuery.trim());
    }).toList();
  }

  void _selectCustomer(MockCustomer customer) {
    Navigator.pop(context, customer.primaryName);
  }

  void _showAddPhoneDialog(MockCustomer customer) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إضافة رقم هاتف', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أضف رقم هاتف لـ ${customer.primaryName}', style: const TextStyle(color: kTextSecondary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: kScaffoldBg, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: kTextPrimary, fontSize: 15),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '07XX XXX XXXX',
                  hintStyle: TextStyle(color: kTextSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حفظ الرقم لـ ${customer.primaryName}'),
                        backgroundColor: kPrimaryDark,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onAddNewCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('شاشة إضافة عميل ستُبرمج لاحقاً'),
        backgroundColor: kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
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
          title: const Text('اختيار عميل', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Column(
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
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search, size: 56, color: kTextSecondary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج',
                            style: const TextStyle(color: kTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _filteredCustomers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        final needsPhoneAlert = (customer.phone == null || customer.phone!.isEmpty) && customer.pendingAmount >= 25000;

                        return AnimatedListItem(
                          index: index,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectCustomer(customer),
                              child: Container(
                                decoration: _neumorphicDecoration(),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
                                          alignment: Alignment.center,
                                          child: Text(
                                            customer.primaryName.isNotEmpty ? customer.primaryName.characters.first : '?',
                                            style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(customer.primaryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                              if (customer.alias != null && customer.alias!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(customer.alias!, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '${customer.pendingOpsCount} عمليات — ${_formatAmount(customer.pendingAmount)} د.ع',
                                                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
                                                ),
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
                                              minimumSize: const Size(0, 36),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('أضف رقم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      },
                    ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24.0, left: 16.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: FloatingActionButton.extended(
              onPressed: _onAddNewCustomer,
              backgroundColor: kPrimaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: const Icon(Icons.person_add, size: 24),
              label: const Text('إضافة عميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
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
}