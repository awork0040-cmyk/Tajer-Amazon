import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import '../services/backup_service.dart';
import 'trash_screen.dart';
import 'backup_screen.dart';
import 'restore_screen.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({Key? key}) : super(key: key);

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  BackupFileInfo? _lastBackup;
  bool _loadingBackup = true;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final latest = await BackupService.instance.getLatestBackup();
    if (!mounted) return;
    setState(() {
      _lastBackup = latest;
      _loadingBackup = false;
    });
  }

  Future<void> _openBackupScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupScreen()),
    );
    await _loadLastBackup();
  }

  Future<void> _openRestoreScreen() async {
    final didRestore = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RestoreScreen()),
    );
    if (didRestore == true) {
      await _loadLastBackup();
    } else {
      await _loadLastBackup();
    }
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

  String _backupSubtitle() {
    if (_loadingBackup) return 'جاري التحميل...';
    if (_lastBackup == null) return 'لا توجد نسخة احتياطية بعد';
    final dt = _lastBackup!.createdAt;
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return 'آخر نسخة: $y-$m-$d $hh:$mm (${_lastBackup!.formattedSize})';
  }

  String _trashSubtitle() {
    final deletedOps = DataService.instance.getDeletedOperations();
    final deletedCustomers = DataService.instance.getDeletedCustomers();

    if (deletedOps.isEmpty && deletedCustomers.isEmpty) {
      return 'لا يوجد عناصر محذوفة';
    }

    int? minDaysRemaining;
    for (final op in deletedOps) {
      if (op.deletedAt != null) {
        final elapsed = DateTime.now().difference(op.deletedAt!).inDays;
        final remaining = 30 - elapsed;
        if (minDaysRemaining == null || remaining < minDaysRemaining) {
          minDaysRemaining = remaining;
        }
      }
    }

    final count = deletedOps.length;
    final customersCount = deletedCustomers.length;
    final parts = <String>[];
    if (count > 0) parts.add('$count عملية');
    if (customersCount > 0) parts.add('$customersCount عميل');

    if (minDaysRemaining == null || minDaysRemaining <= 0) {
      return '${parts.join(' — ')} — قريباً سيُحذف';
    }
    return '${parts.join(' — ')} — متبقي $minDaysRemaining يوماً';
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
            'إدارة البيانات',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: DataService.instance,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _buildListCard(
                    context: context,
                    title: 'النسخ الاحتياطي',
                    subtitle: _backupSubtitle(),
                    icon: Icons.backup_outlined,
                    color: kPrimary,
                    onTap: _openBackupScreen,
                  ),
                  const SizedBox(height: 10),
                  _buildListCard(
                    context: context,
                    title: 'استعادة نسخة',
                    subtitle: 'استعادة البيانات من ملف نسخة احتياطية',
                    icon: Icons.restore_outlined,
                    color: kPrimary,
                    onTap: _openRestoreScreen,
                  ),
                  const SizedBox(height: 10),
                  _buildListCard(
                    context: context,
                    title: 'سلة المحذوفات',
                    subtitle: _trashSubtitle(),
                    icon: Icons.delete_outline,
                    color: const Color(0xFFE53935),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrashScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: _neumorphicDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_back_ios_new,
                color: kTextSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}