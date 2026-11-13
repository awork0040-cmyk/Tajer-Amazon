import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/constants.dart';
import '../services/backup_service.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({Key? key}) : super(key: key);

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF3FB950);
  static const Color _orange = Color(0xFFF0883E);

  bool _isLoading = true;
  bool _isRestoring = false;
  List<BackupFileInfo> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    final list = await BackupService.instance.listBackups();
    if (!mounted) return;
    setState(() {
      _backups = list;
      _isLoading = false;
    });
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

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  // ═══════════════════════════════════════════════════════════
  // تدفق الاستعادة
  // ═══════════════════════════════════════════════════════════

  Future<void> _onPickRestoreFile(BackupFileInfo info) async {
    if (_isRestoring) return;
    if (kIsWeb) {
      _showSnack('الاستعادة متاحة على التطبيق الأصلي فقط', _orange);
      return;
    }
    await _startRestoreFlow(File(info.filePath), _formatDateTime(info.createdAt));
  }

  Future<void> _onPickExternalFile() async {
    if (_isRestoring) return;
    if (kIsWeb) {
      _showSnack('اختيار ملف خارجي متاح على التطبيق الأصلي فقط', _orange);
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) {
        _showSnack('تعذّر الوصول إلى الملف المحدد', _red);
        return;
      }
      final importedPath = await BackupService.instance.importExternalFile(File(path));
      if (importedPath == null) {
        _showSnack('تعذّر استيراد الملف', _red);
        return;
      }
      await _startRestoreFlow(File(importedPath), 'ملف خارجي');
      await _loadBackups();
    } catch (_) {
      _showSnack('تعذّر فتح منتقي الملفات', _red);
    }
  }

  Future<void> _startRestoreFlow(File file, String label) async {
    // 1. قراءة الملخص
    final summary = await BackupService.instance.readSummary(file);
    if (!mounted) return;

    if (!summary.valid) {
      await _showErrorDialog('الملف تالف أو غير صالح', summary.error ?? '');
      return;
    }

    // 2. عرض الملخص
    final confirmed = await _showSummaryDialog(summary, label);
    if (confirmed != true || !mounted) return;

    // 3. تأكيد الاستبدال (كتابة "استبدال")
    final replaceConfirmed = await _showReplaceConfirmDialog();
    if (replaceConfirmed != true || !mounted) return;

    // 4. التنفيذ
    setState(() => _isRestoring = true);
    final result = await BackupService.instance.restoreFromFile(file);
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (result.success) {
      await _showSuccessDialog(result.customerCount, result.operationCount);
      if (!mounted) return;
      await _loadBackups();
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      await _showErrorDialog('فشلت الاستعادة', result.message);
    }
  }

  Future<bool?> _showSummaryDialog(BackupSummary summary, String label) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'استعادة النسخة',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('المصدر', label),
            const SizedBox(height: 6),
            if (summary.createdAt != null)
              _summaryRow('تاريخ الإنشاء', _formatDateTime(summary.createdAt!)),
            const SizedBox(height: 6),
            _summaryRow('عدد العملاء', '${summary.customerCount}'),
            const SizedBox(height: 6),
            _summaryRow('عدد العمليات', '${summary.operationCount}'),
            if (summary.storeName.isNotEmpty) ...[
              const SizedBox(height: 6),
              _summaryRow('اسم المتجر', summary.storeName),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withOpacity(0.35), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _red, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'سيتم مسح كل البيانات الحالية. لا يمكن التراجع.',
                      style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
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
                    backgroundColor: _red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'متابعة',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showReplaceConfirmDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool matches = false;
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            return AlertDialog(
              backgroundColor: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'تأكيد الاستبدال',
                style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اكتب كلمة "استبدال" للمتابعة:',
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
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
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: kTextPrimary, fontSize: 15),
                      onChanged: (v) {
                        setInnerState(() => matches = v.trim() == 'استبدال');
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'استبدال',
                        hintStyle: TextStyle(color: kTextSecondary, fontSize: 14),
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
                        onPressed: matches ? () => Navigator.pop(ctx, true) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          disabledBackgroundColor: _red.withOpacity(0.25),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'استبدال',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _showSuccessDialog(int customerCount, int operationCount) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'تمت الاستعادة',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _green, size: 48),
            const SizedBox(height: 12),
            Text(
              '$customerCount عميل — $operationCount عملية',
              style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'تم إنشاء نسخة حماية تلقائية قبل الاستبدال.',
              style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message.isEmpty ? 'حدث خطأ غير متوقع.' : message,
          style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: kTextSecondary, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════

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
            'استعادة نسخة',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (kIsWeb) _buildWebNotice(),
                        _buildWarningCard(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('النسخ المتاحة'),
                        const SizedBox(height: 10),
                        _buildBackupsList(),
                        const SizedBox(height: 16),
                        _buildPickFileButton(),
                        const SizedBox(height: 12),
                      ],
                    ),
              if (_isRestoring)
                Container(
                  color: Colors.black.withOpacity(0.55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kPrimary),
                        SizedBox(height: 12),
                        Text(
                          'جاري الاستعادة...',
                          style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: _orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'الاستعادة متاحة على التطبيق الأصلي (Android) فقط. على المتصفح، الأزرار ستعرض تنبيهاً.',
              style: TextStyle(color: _orange, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.35), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _red, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'الاستعادة استبدال كلي. تُنشأ نسخة حماية تلقائية قبل التنفيذ.',
              style: TextStyle(color: _red, fontSize: 12, height: 1.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBackupsList() {
    if (_backups.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'لا توجد نسخ احتياطية',
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
      );
    }
    return Column(
      children: _backups.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _neumorphicDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (b.isProtection ? _orange : kPrimary).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        b.isProtection ? Icons.shield_outlined : Icons.folder_zip_outlined,
                        color: b.isProtection ? _orange : kPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(b.createdAt),
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${b.formattedSize} — ${b.customerCount} عميل — ${b.operationCount} عملية',
                            style: const TextStyle(color: kTextSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (b.isProtection)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _orange.withOpacity(0.35), width: 1),
                        ),
                        child: const Text(
                          'حماية',
                          style: TextStyle(color: _orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRestoring ? null : () => _onPickRestoreFile(b),
                    icon: const Icon(Icons.restore, size: 16, color: _red),
                    label: const Text(
                      'استعادة',
                      style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _red.withOpacity(0.5), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickFileButton() {
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: _isRestoring ? null : _onPickExternalFile,
        icon: const Icon(Icons.folder_open, color: kPrimary, size: 20),
        label: const Text(
          'اختيار ملف آخر',
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: kPrimary.withOpacity(0.7),
            width: 1,
            style: BorderStyle.solid,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}