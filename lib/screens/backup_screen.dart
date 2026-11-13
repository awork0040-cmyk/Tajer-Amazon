import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF3FB950);
  static const Color _orange = Color(0xFFF0883E);

  bool _isLoading = true;
  bool _isCreating = false;
  List<BackupFileInfo> _backups = [];

  // إعدادات النسخ التلقائي (واجهة فقط — لم تُحفظ في DataService بعد)
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'daily';
  TimeOfDay _autoBackupTime = const TimeOfDay(hour: 9, minute: 0);

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

  String _relativeDays(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days <= 0) return 'اليوم';
    if (days == 1) return 'منذ يوم';
    if (days == 2) return 'منذ يومين';
    if (days <= 10) return 'منذ $days أيام';
    return 'منذ $days يوماً';
  }

  Future<void> _onCreateBackup() async {
    if (_isCreating) return;
    if (kIsWeb) {
      _showSnack('النسخ الاحتياطي متاح على التطبيق الأصلي فقط', _orange);
      return;
    }
    setState(() => _isCreating = true);
    final result = await BackupService.instance.createBackup();
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (result == null) {
      _showSnack('تعذّر إنشاء النسخة. تحقق من المساحة المتوفرة', _red);
      return;
    }
    await _loadBackups();
    if (!mounted) return;
    _showSnack('تم إنشاء النسخة بنجاح', _green);
  }

  Future<void> _onShareLast() async {
    if (_backups.isEmpty) return;
    if (kIsWeb) {
      _showSnack('المشاركة متاحة على التطبيق الأصلي فقط', _orange);
      return;
    }
    await BackupService.instance.shareBackup(_backups.first.filePath);
    if (!mounted) return;
    _showSnack('جاري فتح خيارات المشاركة...', kPrimary);
  }

  Future<void> _onShareOne(BackupFileInfo info) async {
    if (kIsWeb) {
      _showSnack('المشاركة متاحة على التطبيق الأصلي فقط', _orange);
      return;
    }
    await BackupService.instance.shareBackup(info.filePath);
    if (!mounted) return;
    _showSnack('جاري فتح خيارات المشاركة...', kPrimary);
  }

  Future<void> _onDeleteOne(BackupFileInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'حذف النسخة',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'سيتم حذف الملف "${info.fileName}" نهائياً.',
          style: const TextStyle(color: kTextSecondary, fontSize: 14),
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
                    backgroundColor: _red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'حذف',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await BackupService.instance.deleteBackup(info.filePath);
    await _loadBackups();
    if (!mounted) return;
    _showSnack('تم حذف النسخة', _red);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _autoBackupTime,
    );
    if (picked != null && mounted) {
      setState(() => _autoBackupTime = picked);
    }
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
            'النسخ الاحتياطي',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (kIsWeb) _buildWebNotice(),
                    _buildLastBackupCard(),
                    const SizedBox(height: 12),
                    _buildCreateButton(),
                    const SizedBox(height: 10),
                    _buildShareLastButton(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('النسخ السابقة'),
                    const SizedBox(height: 10),
                    _buildBackupsList(),
                    const SizedBox(height: 20),
                    _buildAutoBackupCard(),
                    const SizedBox(height: 12),
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
              'النسخ الاحتياطي متاح على التطبيق الأصلي (Android) فقط. على المتصفح، الأزرار ستعرض تنبيهاً بدل الحفظ.',
              style: TextStyle(color: _orange, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastBackupCard() {
    final last = _backups.isEmpty ? null : _backups.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _neumorphicDecoration(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: last != null ? kPrimary : kTextSecondary.withOpacity(0.5),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'آخر نسخة احتياطية',
            style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (last == null)
            const Text(
              'لا توجد نسخة احتياطية بعد',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            )
          else ...[
            Text(
              _formatDateTime(last.createdAt),
              style: const TextStyle(color: kTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.35), width: 1),
              ),
              child: Text(
                _relativeDays(last.createdAt),
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isCreating ? null : _onCreateBackup,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            disabledBackgroundColor: kPrimary.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'إنشاء نسخة الآن',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildShareLastButton() {
    final enabled = _backups.isNotEmpty;
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: enabled ? _onShareLast : null,
        icon: Icon(
          Icons.share_outlined,
          color: enabled ? kPrimary : kTextSecondary.withOpacity(0.4),
          size: 20,
        ),
        label: Text(
          'مشاركة آخر نسخة',
          style: TextStyle(
            color: enabled ? kPrimary : kTextSecondary.withOpacity(0.4),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: enabled ? kPrimary.withOpacity(0.7) : kTextSecondary.withOpacity(0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
          'لا توجد نسخ سابقة',
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
      );
    }
    final visible = _backups.take(3).toList();
    return Column(
      children: visible.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _neumorphicDecoration(),
            child: Row(
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _onShareOne(b),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.share_outlined, color: kPrimary, size: 18),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _onDeleteOne(b),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.delete_outline, color: _red, size: 18),
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

  Widget _buildAutoBackupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'النسخ التلقائي',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _autoBackupEnabled,
                activeColor: kPrimary,
                onChanged: (v) {
                  setState(() => _autoBackupEnabled = v);
                  _showSnack(
                    'النسخ التلقائي سيُفعّل بعد ربط قاعدة البيانات',
                    _orange,
                  );
                },
              ),
            ],
          ),
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 6),
            const Text(
              'التكرار',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kScaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _autoBackupFrequency,
                  isExpanded: true,
                  dropdownColor: kSurfaceColor,
                  iconEnabledColor: kPrimary,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('يومي')),
                    DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _autoBackupFrequency = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'الوقت',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: kScaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: kPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_autoBackupTime.hour.toString().padLeft(2, '0')}:${_autoBackupTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: kTextPrimary, fontSize: 14),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: الحفظ الدائم للإعدادات سيُضاف مع Drift.',
              style: TextStyle(color: kTextSecondary, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}