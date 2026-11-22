import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';

const Color kSilver = Color(0xFFB0BEC5);

class CustomerHistoryScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CustomerHistoryScreen({Key? key, required this.customerId, required this.customerName}) : super(key: key);

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
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

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final delivered = DataService.instance.getOperationsForCustomer(widget.customerId)
              .where((o) => o.status == OperationStatus.delivered).toList()
            ..sort((a, b) => (b.deliveredAt ?? b.createdAt).compareTo(a.deliveredAt ?? a.createdAt));
          final totalAmount = delivered.fold<int>(0, (s, o) => s + o.amount);

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              title: Text(widget.customerName, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _statBox('العمليات', '${delivered.length}')),
                        const SizedBox(width: 10),
                        Expanded(child: _statBox('الإجمالي', '${_formatAmount(totalAmount)} د.ع')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: delivered.isEmpty
                        ? const Center(child: Text('لا توجد عمليات مكتملة بعد', style: TextStyle(color: kTextSecondary, fontSize: 14)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: delivered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final op = delivered[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: _neumorphicDecoration(radius: 12),
                                child: Row(
                                  children: [
                                    Container(width: 4, height: 42, decoration: BoxDecoration(color: kSilver, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(op.serial, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14), textDirection: TextDirection.ltr),
                                          const SizedBox(height: 4),
                                          Text(
                                            op.deliveredAt != null ? 'تم التوصيل: ${_formatDate(op.deliveredAt!)}' : 'تم التوصيل',
                                            style: const TextStyle(color: kTextSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text('${_formatAmount(op.amount)} د.ع', style: const TextStyle(color: kSilver, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
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

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _neumorphicDecoration(radius: 12),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}