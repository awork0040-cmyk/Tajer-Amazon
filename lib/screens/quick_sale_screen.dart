import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';
import 'customer_selection_screen.dart';
import 'recent_operations_screen.dart';
import 'printer_settings_screen.dart';

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
  final FocusNode _nameFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  bool _isGift = false;
  bool _isSaving = false;
  bool _printerConnected = false;

  bool _showSuggestions = false;
  List<MockCustomer> _suggestions = [];
  MockCustomer? _exactMatchCustomer;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _normalizeArabic(String input) {
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

  void _onNameChanged(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _showSuggestions = false;
        _suggestions = [];
        _exactMatchCustomer = null;
        return;
      }

      final normalizedQuery = _normalizeArabic(trimmed);

      _exactMatchCustomer = null;
      for (var c in DataService.instance.customers) {
        if (_normalizeArabic(c.primaryName) == normalizedQuery) {
          _exactMatchCustomer = c;
          break;
        }
      }

      _suggestions = DataService.instance.customers.where((c) {
        final normPrimary = _normalizeArabic(c.primaryName);
        if (normPrimary.startsWith(normalizedQuery)) return true;
        for (var alias in c.aliases) {
          if (_normalizeArabic(alias).startsWith(normalizedQuery)) return true;
        }
        return false;
      }).toList();

      _showSuggestions = true;
    });
  }

  void _selectSuggestion(MockCustomer customer) {
    setState(() {
      _nameController.text = customer.primaryName;
      _exactMatchCustomer = customer;
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _onSubmitted(String value) {
    if (_exactMatchCustomer != null) {
      _selectSuggestion(_exactMatchCustomer!);
    } else {
      FocusScope.of(context).unfocus();
    }
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
    return _exactMatchCustomer != null && (_amount != '0' || _isGift) && !_isSaving;
  }

  Future<void> _openCustomerSelection() async {
    final resultName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CustomerSelectionScreen()),
    );
    if (resultName != null && resultName.isNotEmpty) {
      MockCustomer? found;
      for (var c in DataService.instance.customers) {
        if (c.primaryName == resultName) {
          found = c;
          break;
        }
      }
      if (found != null) {
        _nameController.text = found.primaryName;
        setState(() {
          _exactMatchCustomer = found;
          _showSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      }
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
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

    final amountValue = int.tryParse(_amount) ?? 0;
    DataService.instance.addOperation(
      customerId: _exactMatchCustomer!.id,
      amount: amountValue,
      isGift: _isGift,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _amount = '0';
      _nameController.clear();
      _exactMatchCustomer = null;
      _isGift = false;
      _isSaving = false;
      _showSuggestions = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم الحفظ بنجاح'),
        backgroundColor: const Color(0xFF3FB950),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openPrinterSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()));
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
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (_showSuggestions) setState(() => _showSuggestions = false);
            },
            child: Stack(
              children: [
                Padding(
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
                if (_showSuggestions && _suggestions.isNotEmpty)
                  CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, 58),
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width - (kPagePadding * 2),
                          decoration: _neumorphicDecoration(radius: 12),
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                            itemBuilder: (context, index) {
                              final customer = _suggestions[index];
                              final normalizedTyped = _normalizeArabic(_nameController.text);
                              final isExactPrimaryMatch = _normalizeArabic(customer.primaryName) == normalizedTyped;

                              return InkWell(
                                onTap: () => _selectSuggestion(customer),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(customer.primaryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                            if (customer.aliases.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(customer.aliases.join('، '), style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isExactPrimaryMatch)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                                          child: const Icon(Icons.check, color: Colors.green, size: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 70,
      leadingWidth: 70,
      leading: Center(child: _buildFloatingButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
      title: const Text('البيع السريع', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
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
              const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('د.ع', style: TextStyle(color: kTextSecondary, fontSize: 15))),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: _neumorphicDecoration(),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              style: const TextStyle(color: kTextPrimary, fontSize: 15),
              textAlignVertical: TextAlignVertical.center,
              onChanged: _onNameChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'اسم العميل...',
                hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.person, color: kTextSecondary, size: 22),
                prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                suffixIcon: _exactMatchCustomer != null
                    ? const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(Icons.check_circle, color: Colors.green, size: 22),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                isCollapsed: false,
              ),
            ),
          ),
        ),
        if (_nameController.text.isNotEmpty && _exactMatchCustomer == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Text('الاسم غير موجود. اختر عميلاً أو أضف عميلاً جديداً.', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _actionButton(icon: Icons.group, label: 'اختيار عميل', onTap: _openCustomerSelection)),
        const SizedBox(width: kSpacingInner),
        Expanded(child: _actionButton(icon: Icons.list, label: 'العمليات', onTap: _openRecentOperations)),
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
                boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
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
                  child: Icon(Icons.print, color: _printerConnected ? const Color(0xFF4CAF50) : const Color(0xFFE53935), size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}