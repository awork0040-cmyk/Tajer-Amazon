import 'package:flutter/material.dart';
import 'customer_selection_screen.dart';
import 'recent_operations_screen.dart';
import 'placeholder_screen.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kPrimaryDark = Color(0xFF1565C0);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

const double kSpacingSection = 8;
const double kSpacingInner = 6;
const double kPaddingCard = 10;
const double kIconGap = 6;
const double kPagePadding = 8;

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({Key? key}) : super(key: key);

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  String _amount = '0';
  final TextEditingController _nameController = TextEditingController();
  bool _isGift = false;
  bool _isSaving = false;
  bool _printerConnected = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    setState(() {
      if (_amount == '0') {
        _amount = digit;
      } else if (_amount.length < 12) {
        _amount = '$_amount$digit';
      }
    });
  }

  void _onTripleZero() {
    setState(() {
      if (_amount == '0') return;
      if (_amount.length + 3 <= 12) _amount = '${_amount}000';
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length <= 1) {
        _amount = '0';
      } else {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  void _onClearAll() => setState(() => _amount = '0');

  String _formattedAmount() {
    if (_amount.isEmpty) return '0';
    final buffer = StringBuffer();
    for (int i = 0; i < _amount.length; i++) {
      if (i > 0 && (_amount.length - i) % 3 == 0) buffer.write(',');
      buffer.write(_amount[i]);
    }
    return buffer.toString();
  }

  bool get _canSave {
    final hasName = _nameController.text.trim().isNotEmpty;
    final amountValue = int.tryParse(_amount) ?? 0;
    final hasValidAmount = amountValue > 0 || _isGift;
    return hasName && hasValidAmount && !_isSaving;
  }

  Future<void> _openCustomerSelection() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CustomerSelectionScreen()),
    );
    if (result != null && result.isNotEmpty) {
      _nameController.text = result;
      setState(() {});
    }
  }

  void _openRecentOperations() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentOperationsScreen()));
  }

  void _onGiftPressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الهدية', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text('سيتم تصفير المبلغ وحفظ العملية كهدية. هل تريد المتابعة؟', style: TextStyle(color: kTextSecondary, fontSize: 14), textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
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
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _amount = '0';
                      _isGift = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD29922),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تأكيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveAndPrint() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _amount = '0';
      _nameController.clear();
      _isGift = false;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم الحفظ (الطباعة ستُبرمج لاحقاً)'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openPrinterSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'إعدادات الطابعة')));
  }

  // تم تبسيط التصميم لضمان عمله على المتصفح بدون أخطاء
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(kPagePadding),
            child: Column(
              children: [
                _buildAmountBox(),
                const SizedBox(height: kSpacingSection),
                _buildCustomerField(),
                const SizedBox(height: kSpacingSection),
                _buildActionButtons(),
                const SizedBox(height: kSpacingSection),
                Expanded(child: _buildNumberPad()),
                const SizedBox(height: kSpacingSection),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
        'البيع السريع',
        style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildAmountBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _neumorphicDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('المبلغ الإجمالي', style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: kSpacingInner),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formattedAmount(), style: const TextStyle(color: kTextPrimary, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: kIconGap),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('د.ع', style: TextStyle(color: kTextSecondary, fontSize: 15)),
              ),
              if (_isGift) ...[
                const SizedBox(width: kIconGap),
                const Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerField() {
    return Container(
      decoration: _neumorphicDecoration(),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: kTextPrimary, fontSize: 15),
        textAlignVertical: TextAlignVertical.center,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'اسم العميل...',
          hintStyle: TextStyle(color: kTextSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.person, color: kTextSecondary, size: 22),
          prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 44),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          isCollapsed: false,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(icon: Icons.group, label: 'اختيار عميل', onTap: _openCustomerSelection),
        ),
        const SizedBox(width: kSpacingInner),
        Expanded(
          child: _actionButton(icon: Icons.list, label: 'العمليات', onTap: _openRecentOperations),
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: kPaddingCard),
          decoration: _neumorphicDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kPrimary, size: 18),
              const SizedBox(width: kIconGap),
              Text(label, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Expanded(child: _numRow(['7', '8', '9'])),
        Expanded(child: _numRow(['4', '5', '6'])),
        Expanded(child: _numRow(['1', '2', '3'])),
        Expanded(child: _lastRow()),
      ],
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      children: digits
          .map((d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _numButton(d, () => _onDigit(d)),
                ),
              ))
          .toList(),
    );
  }

  Widget _lastRow() {
    return Row(
      children: [
        Expanded(child: Padding(padding: const EdgeInsets.all(4), child: _deleteButton())),
        Expanded(child: Padding(padding: const EdgeInsets.all(4), child: _numButton('0', () => _onDigit('0')))),
        Expanded(child: Padding(padding: const EdgeInsets.all(4), child: _numButton('000', _onTripleZero))),
      ],
    );
  }

  Widget _numButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: _neumorphicDecoration(),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _onBackspace,
        onLongPress: _onClearAll,
        child: Container(
          decoration: _neumorphicDecoration(color: const Color(0xFF2B1719)),
          alignment: Alignment.center,
          child: const Icon(Icons.backspace, color: Color(0xFFE53935), size: 22),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _canSave ? _onSaveAndPrint : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryDark,
                  disabledBackgroundColor: const Color(0xFF1C2733),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('حفظ وطباعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: kSpacingInner),
          SizedBox(
            width: 60,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _onGiftPressed,
                child: Container(
                  decoration: _neumorphicDecoration(color: const Color(0xFF2D2410)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.card_giftcard, color: Color(0xFFFFC107), size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: kSpacingInner),
          SizedBox(
            width: 60,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openPrinterSettings,
                child: Container(
                  decoration: _neumorphicDecoration(
                    color: _printerConnected ? const Color(0xFF1B2E1E) : const Color(0xFF2B1719),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.print,
                    color: _printerConnected ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}