import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kPrimaryDark = Color(0xFF1565C0);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

class MockOperation {
  final String serial;
  final String customerName;
  final int amount;

  MockOperation({
    required this.serial,
    required this.customerName,
    required this.amount,
  });
}

final List<MockOperation> _mockOperations = [
  MockOperation(serial: 'TA1-1050', customerName: 'أحمد علي', amount: 25000),
  MockOperation(serial: 'TA1-1051', customerName: 'حميدة سالم', amount: 15000),
  MockOperation(serial: 'TA1-1052', customerName: 'زينب حسن', amount: 42000),
  MockOperation(serial: 'TA1-1053', customerName: 'علي جاسم', amount: 8000),
  MockOperation(serial: 'TA1-1054', customerName: 'محمد كريم', amount: 32000),
  MockOperation(serial: 'TA1-1055', customerName: 'نور الهدى', amount: 50000),
];

class RecentOperationsScreen extends StatefulWidget {
  const RecentOperationsScreen({Key? key}) : super(key: key);

  @override
  State<RecentOperationsScreen> createState() => _RecentOperationsScreenState();
}

class _RecentOperationsScreenState extends State<RecentOperationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockOperation> get _filteredOps {
    if (_searchQuery.isEmpty) return _mockOperations;
    return _mockOperations.where((op) => 
      op.customerName.contains(_searchQuery) || op.serial.contains(_searchQuery)
    ).toList();
  }

  void _showOptionsSheet(MockOperation op) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(op.customerName, style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildSheetItem(icon: Icons.edit, title: 'تعديل العملية', color: kPrimary, onTap: () => Navigator.pop(context)),
                _buildSheetItem(icon: Icons.print, title: 'إعادة طباعة', color: kPrimary, onTap: () => Navigator.pop(context)),
                _buildSheetItem(
                  icon: Icons.copy,
                  title: 'نسخ رقم التسلسل',
                  color: kTextPrimary,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: op.serial));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم نسخ التسلسل'),
                        backgroundColor: kPrimaryDark,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                _buildSheetItem(icon: Icons.delete_outline, title: 'حذف', color: const Color(0xFFE53935), onTap: () => Navigator.pop(context)),
                const Divider(color: Colors.white12, height: 30),
                _buildSheetItem(icon: Icons.cancel_outlined, title: 'إلغاء', color: kTextSecondary, onTap: () => Navigator.pop(context)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
          title: const Text('آخر العمليات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    hintText: 'ابحث بالاسم أو رقم التسلسل...',
                    hintStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, color: kTextSecondary, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: kPrimary, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('العمليات من آخر 24 ساعة', style: TextStyle(color: kTextSecondary.withOpacity(0.7), fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredOps.isEmpty
                  ? Center(child: Text('لا توجد عمليات', style: TextStyle(color: kTextSecondary, fontSize: 14)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _filteredOps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final op = _filteredOps[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showOptionsSheet(op),
                            child: Container(
                              decoration: _neumorphicDecoration(),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(op.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kTextPrimary, fontSize: 13)),
                                      Text(op.serial, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
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