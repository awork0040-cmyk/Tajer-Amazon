import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';

class WhatsAppMessagesScreen extends StatefulWidget {
  const WhatsAppMessagesScreen({Key? key}) : super(key: key);

  @override
  State<WhatsAppMessagesScreen> createState() => _WhatsAppMessagesScreenState();
}

class _WhatsAppMessagesScreenState extends State<WhatsAppMessagesScreen> {
  static const String _defaultTemplate =
      'مرحباً [اسم العميل]،\n'
      'شكراً لطلبك من [اسم المتجر].\n'
      'المبلغ الإجمالي: [المبلغ] د.ع.\n'
      'عدد الطلبات: [عدد الطلبات].\n'
      'التاريخ: [التاريخ].';

  static const List<String> _variables = [
    '[اسم العميل]',
    '[المبلغ]',
    '[عدد الطلبات]',
    '[التاريخ]',
    '[اسم المتجر]',
    '[رقم التسلسل]',
  ];

  late final TextEditingController _controller;
  bool _showOpsList = false;
  int _opsFormat = 0; // 0 = تسلسل+سعر، 1 = سعر فقط
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: DataService.instance.getWhatsAppTemplate());
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _insertVariable(String variable) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.start >= 0 ? selection.start : text.length;
    final newText = text.substring(0, cursor) + variable + text.substring(cursor);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + variable.length),
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

  /// يبني نص المعاينة بقيم وهمية.
  String _buildPreviewText() {
    final storeName = DataService.instance.getStoreName();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String preview = _controller.text;
    preview = preview.replaceAll('[اسم العميل]', 'علي سالم');
    preview = preview.replaceAll('[المبلغ]', _formatAmount(25000));
    preview = preview.replaceAll('[عدد الطلبات]', '3');
    preview = preview.replaceAll('[التاريخ]', dateStr);
    preview = preview.replaceAll('[اسم المتجر]', storeName);
    preview = preview.replaceAll('[رقم التسلسل]', 'TA1-1051');

    if (_showOpsList) {
      final opsHeader = _opsFormat == 0 ? '\n\nالعمليات:' : '\n\nالمبالغ:';
      final opsLines = _opsFormat == 0
          ? 'TA1-1051 — 25,000 د.ع\nTA1-1052 — 15,000 د.ع\nTA1-1053 — 10,000 د.ع'
          : '25,000 د.ع\n15,000 د.ع\n10,000 د.ع';
      preview = '$preview$opsHeader\n$opsLines';
    }

    return preview;
  }

  Future<void> _onReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'إعادة تعيين القالب',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'سيتم استعادة القالب الافتراضي. هل تريد المتابعة؟',
          style: TextStyle(color: kTextSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إعادة تعيين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _controller.text = _defaultTemplate;
    setState(() {
      _showOpsList = false;
      _opsFormat = 0;
    });
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnack('لا يمكن حفظ قالب فارغ', const Color(0xFFE53935));
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    DataService.instance.setWhatsAppTemplate(text);
    setState(() => _isSaving = false);
    if (!mounted) return;
    _showSnack('تم حفظ القالب', const Color(0xFF3FB950));
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
          title: const Text(
            'رسائل WhatsApp',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEditorCard(),
              const SizedBox(height: 12),
              _buildPreviewCard(),
              const SizedBox(height: 16),
              _buildBottomButtons(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'القالب النصي',
            style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kScaffoldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _controller,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'اكتب نص الرسالة هنا...',
                hintStyle: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'المتغيرات (اضغط للإدراج)',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _variables.map((v) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _insertVariable(v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPrimary.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      v,
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.05), height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'إظهار قائمة العمليات',
                  style: TextStyle(color: kTextPrimary, fontSize: 14),
                ),
              ),
              Switch(
                value: _showOpsList,
                activeColor: kPrimary,
                onChanged: (v) => setState(() => _showOpsList = v),
              ),
            ],
          ),
          if (_showOpsList) ...[
            const SizedBox(height: 4),
            RadioListTile<int>(
              value: 0,
              groupValue: _opsFormat,
              activeColor: kPrimary,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'التسلسل + السعر',
                style: TextStyle(color: kTextPrimary, fontSize: 13),
              ),
              onChanged: (v) => setState(() => _opsFormat = v ?? 0),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: _opsFormat,
              activeColor: kPrimary,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'السعر فقط',
                style: TextStyle(color: kTextPrimary, fontSize: 13),
              ),
              onChanged: (v) => setState(() => _opsFormat = v ?? 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معاينة',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF075E54),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.zero,
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              _buildPreviewText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: TextButton(
              onPressed: _onReset,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
              child: const Text(
                'إعادة تعيين القالب',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 55,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryDark.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryDark,
                  disabledBackgroundColor: const Color(0xFF1C2733),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}