import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';

class StoreNameScreen extends StatefulWidget {
  const StoreNameScreen({Key? key}) : super(key: key);

  @override
  State<StoreNameScreen> createState() => _StoreNameScreenState();
}

class _StoreNameScreenState extends State<StoreNameScreen> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: DataService.instance.getStoreName());
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

  bool get _canSave {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return false;
    if (_isSaving) return false;
    return trimmed != DataService.instance.getStoreName();
  }

  Future<void> _onSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    DataService.instance.setStoreName(_controller.text);
    setState(() => _isSaving = false);
    if (!mounted) return;
    _showSnack('تم حفظ اسم المتجر', const Color(0xFF3FB950));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.trim().length;
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
            'اسم المتجر',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: _neumorphicDecoration(radius: 12),
                  child: TextField(
                    controller: _controller,
                    maxLength: 50,
                    maxLines: 1,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSave(),
                    decoration: InputDecoration(
                      hintText: 'اسم المتجر',
                      hintStyle: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.store,
                        color: kTextSecondary,
                        size: 22,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      counterStyle: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يظهر هذا الاسم في أعلى الملصقات المطبوعة.',
                  style: TextStyle(
                    color: kTextSecondary.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _canSave
                          ? [
                              BoxShadow(
                                color: kPrimaryDark.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _canSave ? _onSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryDark,
                        disabledBackgroundColor: const Color(0xFF1C2733),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              length == 0 ? 'حفظ' : 'حفظ ($length/50)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
}