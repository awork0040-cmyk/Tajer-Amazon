import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import '../widgets/animated_list_item.dart';

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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showOptionsSheet(Operation op) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(op.customerName, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12, thickness: 0.5, height: 1),
                const SizedBox(height: 8),
                _buildSheetItem(icon: Icons.edit, title: 'تعديل العملية', iconColor: const Color(0xFFF0883E), textColor: Colors.white, onTap: () { Navigator.pop(context); _showEditDialog(op); }),
                _buildSheetItem(icon: Icons.print, title: 'إعادة طباعة', iconColor: const Color(0xFF3FB950), textColor: Colors.white, onTap: () { Navigator.pop(context); _showSnack('إعادة الطباعة ستُبرمج لاحقاً', kPrimaryDark); }),
                _buildSheetItem(icon: Icons.copy, title: 'نسخ رقم التسلسل', iconColor: kPrimary, textColor: Colors.white, onTap: () { Clipboard.setData(ClipboardData(text: op.serial)); Navigator.pop(context); _showSnack('تم نسخ التسلسل', kPrimaryDark); }),
                _buildSheetItem(icon: Icons.delete_outline, title: 'حذف', iconColor: Colors.red, textColor: Colors.red, onTap: () { Navigator.pop(context); _confirmDelete(op); }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({required IconData icon, required String title, required Color iconColor, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Operation op) {
    final amountController = TextEditingController(text: op.amount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تعديل العملية', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(labelText: 'المبلغ الجديد', labelStyle: TextStyle(color: kTextSecondary)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () {
              final newAmount = int.tryParse(amountController.text.trim());
              if (newAmount == null || newAmount < 0) { _showSnack('المبلغ غير صالح', Colors.red); return; }
              Navigator.pop(ctx);
              DataService.instance.updateOperation(op.id, newAmount: newAmount);
              _showSnack('تم تحديث العملية برقم تسلسل جديد', Colors.green);
            },
            child: const Text('حفظ', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Operation op) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف العملية', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text('سيتم نقل العملية ${op.serial} إلى سلة المحذوفات. هل تريد المتابعة؟', style: const TextStyle(color: kTextSecondary, fontSize: 14), textAlign: TextAlign.center),
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
                  onPressed: () { Navigator.pop(ctx); DataService.instance.deleteOperation(op.id); _showSnack('تم نقل العملية لسلة المحذوفات', Colors.red); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
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
          leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
          title: const Text('آخر العمليات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: ListenableBuilder(
          listenable: DataService.instance,
          builder: (context, _) {
            final ops = DataService.instance.getRecentOperations();
            final filtered = _searchQuery.isEmpty
                ? ops
                : ops.where((o) => DataService.instance.normalizeArabic(o.customerName).contains(DataService.instance.normalizeArabic(_searchQuery)) || o.serial.contains(_searchQuery)).toList();

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
                        hintText: 'ابحث بالاسم أو رقم التسلسل...',
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
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا توجد عمليات في آخر 24 ساعة', style: TextStyle(color: kTextSecondary, fontSize: 14)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final op = filtered[index];
                            return AnimatedListItem(
                              index: index,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showOptionsSheet(op),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: _neumorphicDecoration(),
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
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}