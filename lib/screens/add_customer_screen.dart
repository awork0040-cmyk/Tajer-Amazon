import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';

class AddCustomerScreen extends StatefulWidget {
  final bool isFullVersion;
  final MockCustomer? customerToEdit;

  const AddCustomerScreen({Key? key, this.isFullVersion = true, this.customerToEdit}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final List<TextEditingController> _secondaryPhones = [];
  String? _nameError;
  String? _phoneError;
  bool _isVip = false;

  // لحفظ البيانات الأصلية للمقارنة
  String _initialName = '';
  String _initialAlias = '';
  String _initialPhone = '';
  String _initialAddress = '';
  String _initialNotes = '';

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      _nameController.text = widget.customerToEdit!.primaryName;
      _phoneController.text = widget.customerToEdit!.primaryPhone ?? '';
      _addressController.text = widget.customerToEdit!.address ?? '';
      _notesController.text = widget.customerToEdit!.notes ?? '';
      _isVip = widget.customerToEdit!.isVip;
      
      if (widget.customerToEdit!.aliases.isNotEmpty) {
        _aliasController.text = widget.customerToEdit!.aliases.first;
      }

      _initialName = _nameController.text;
      _initialAlias = _aliasController.text;
      _initialPhone = _phoneController.text;
      _initialAddress = _addressController.text;
      _initialNotes = _notesController.text;
      
      int count = 0;
      for (var p in widget.customerToEdit!.secondaryPhones) {
        if (count >= 2) break;
        _secondaryPhones.add(TextEditingController(text: p));
        count++;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    for (var c in _secondaryPhones) { c.dispose(); }
    super.dispose();
  }

  // مقارنة الحالية بالأصلية
  bool get _hasChanges {
    return _nameController.text != _initialName ||
           _aliasController.text != _initialAlias ||
           _phoneController.text != _initialPhone ||
           _addressController.text != _initialAddress ||
           _notesController.text != _initialNotes;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('لديك تغييرات غير محفوظة', style: TextStyle(color: kTextPrimary)),
        content: const Text('هل تريد الإلغاء والخروج؟', style: TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('متابعة التعديل')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إلغاء والخروج', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return result ?? false;
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty) {
      if (widget.isFullVersion) return 'رقم الهاتف مطلوب';
      return null;
    }
    if (phone.length < 11) return 'الرقم يبدو غير صالح';
    return null;
  }

  void _onSave() {
    setState(() {
      _nameError = null;
      _phoneError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'اسم العميل مطلوب';
      }

      if (widget.isFullVersion || _phoneController.text.isNotEmpty) {
        _phoneError = _validatePhone(_phoneController.text.trim());
      }

      if (_nameError != null || _phoneError != null) return;
    });

    final newCustomer = MockCustomer(
      id: widget.customerToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      primaryName: _nameController.text.trim(),
      primaryPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      secondaryPhones: _secondaryPhones.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      aliases: _aliasController.text.trim().isEmpty ? [] : [_aliasController.text.trim()],
      isVip: _isVip,
    );

    Navigator.pop(context, newCustomer);
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

  Widget _buildInlineField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSecondary),
        floatingLabelStyle: const TextStyle(color: kPrimary),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
        prefixIcon: icon != null ? Icon(icon, color: kTextSecondary, size: 20) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: kScaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: kPrimary), onPressed: () async {
              if (await _onWillPop()) Navigator.pop(context);
            }),
            title: Text(widget.customerToEdit == null ? 'عميل جديد' : 'تعديل العميل', style: const TextStyle(color: kTextPrimary, fontSize: 16)),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _neumorphicDecoration(),
                  child: Column(
                    children: [
                      _buildInlineField(controller: _nameController, label: 'اسم العميل الأساسي *', icon: Icons.person, errorText: _nameError),
                      const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                      _buildInlineField(controller: _aliasController, label: 'اسم مستعار أو كنية', icon: Icons.badge),
                      const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                      _buildInlineField(
                        controller: _phoneController, 
                        label: widget.isFullVersion ? 'رقم الهاتف الأساسي *' : 'رقم الهاتف (اختياري)', 
                        icon: Icons.phone, 
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                      ),
                      ..._secondaryPhones.asMap().entries.map((entry) {
                        return Column(
                          children: [
                            const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                            Row(
                              children: [
                                Expanded(child: _buildInlineField(controller: entry.value, label: 'رقم هاتف ثانوي', icon: Icons.phone, keyboardType: TextInputType.phone)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => setState(() { _secondaryPhones.removeAt(entry.key).dispose(); }),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                      if (_secondaryPhones.length < 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () => setState(() => _secondaryPhones.add(TextEditingController())),
                            icon: const Icon(Icons.add, color: kPrimary, size: 18),
                            label: const Text('إضافة رقم هاتف ثانوي', style: TextStyle(color: kPrimary, fontSize: 12)),
                          ),
                        ),
                      const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                      _buildInlineField(controller: _addressController, label: 'العنوان', icon: Icons.location_on, maxLines: 2),
                      const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                      _buildInlineField(controller: _notesController, label: 'ملاحظات', icon: Icons.notes, maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}