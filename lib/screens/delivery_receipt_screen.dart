import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';

class DeliveryReceiptScreen extends StatelessWidget {
  final MockCustomer customer;
  final List<Operation> operations;
  final int totalAmount;
  final DateTime dateTime;

  const DeliveryReceiptScreen({
    super.key,
    required this.customer,
    required this.operations,
    required this.totalAmount,
    required this.dateTime,
  });

  String _formatNumber(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  String _buildWhatsAppMessage() {
    final storeName = DataService.instance.getStoreName();
    final template = DataService.instance.getWhatsAppTemplate();
    final firstSerial = operations.isNotEmpty ? operations.first.serial : '';
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

    String msg = template;
    msg = msg.replaceAll('[اسم العميل]', customer.primaryName);
    msg = msg.replaceAll('[المبلغ]', _formatNumber(totalAmount));
    msg = msg.replaceAll('[عدد الطلبات]', '${operations.length}');
    msg = msg.replaceAll('[التاريخ]', dateStr);
    msg = msg.replaceAll('[اسم المتجر]', storeName);
    msg = msg.replaceAll('[رقم التسلسل]', firstSerial);
    return msg;
  }

  Future<void> _sendToWhatsApp(BuildContext context) async {
    String rawPhone = (customer.primaryPhone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (rawPhone.startsWith('07') && rawPhone.length == 11) {
      rawPhone = '964${rawPhone.substring(1)}';
    } else if (rawPhone.startsWith('+')) {
      rawPhone = rawPhone.substring(1);
    }

    final encodedText = Uri.encodeComponent(_buildWhatsAppMessage());
    final uri = rawPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$rawPhone?text=$encodedText')
        : Uri.parse('https://wa.me/?text=$encodedText');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر فتح واتساب'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryPhone = (customer.primaryPhone != null && customer.primaryPhone!.isNotEmpty)
        ? customer.primaryPhone!
        : 'غير محدد';
    final secondaryPhone = customer.secondaryPhones.isNotEmpty
        ? customer.secondaryPhones.join(' • ')
        : 'غير محدد';
    final address = (customer.address != null && customer.address!.isNotEmpty)
        ? customer.address!
        : 'غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.92) / 0.08).clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'وصل التوصيل',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLine('العميل', customer.primaryName, isPrimary: true),
                  const SizedBox(height: 8),
                  _buildLine('الأساسي', primaryPhone, isLtr: true),
                  const SizedBox(height: 8),
                  _buildLine('الاحتياطي', secondaryPhone, isLtr: true),
                  const SizedBox(height: 8),
                  _buildLine('العنوان', address),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                  _buildLine('المبلغ', '${_formatNumber(totalAmount)} د.ع', isPrimary: true),
                  const SizedBox(height: 8),
                  _buildLine('عدد الطلبات', '${operations.length}'),
                  const SizedBox(height: 8),
                  _buildLine('التاريخ', _formatDate(dateTime), isLtr: true),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ElevatedButton(
                          onPressed: () => _sendToWhatsApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'واتساب',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextPrimary,
                            side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إغلاق',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLine(
    String label,
    String value, {
    bool isPrimary = false,
    bool isLtr = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textDirection: isLtr ? TextDirection.ltr : null,
            textAlign: isLtr ? TextAlign.right : TextAlign.start,
            style: TextStyle(
              color: isPrimary ? kTextPrimary : kTextPrimary.withOpacity(0.85),
              fontSize: isPrimary ? 14 : 13.5,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
