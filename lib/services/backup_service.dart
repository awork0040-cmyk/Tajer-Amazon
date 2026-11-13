import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';
import 'data_service.dart';

class BackupFileInfo {
  final String fileName;
  final String filePath;
  final int sizeBytes;
  final int customerCount;
  final int operationCount;
  final DateTime createdAt;
  final bool isProtection;

  const BackupFileInfo({
    required this.fileName,
    required this.filePath,
    required this.sizeBytes,
    required this.customerCount,
    required this.operationCount,
    required this.createdAt,
    this.isProtection = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupSummary {
  final bool valid;
  final String? error;
  final DateTime? createdAt;
  final int customerCount;
  final int operationCount;
  final String storeName;

  const BackupSummary({
    required this.valid,
    this.error,
    this.createdAt,
    this.customerCount = 0,
    this.operationCount = 0,
    this.storeName = '',
  });

  factory BackupSummary.invalid(String err) =>
      BackupSummary(valid: false, error: err);
}

class RestoreResult {
  final bool success;
  final String message;
  final int customerCount;
  final int operationCount;

  const RestoreResult._({
    required this.success,
    required this.message,
    this.customerCount = 0,
    this.operationCount = 0,
  });

  factory RestoreResult.success({
    required int customerCount,
    required int operationCount,
  }) =>
      RestoreResult._(
        success: true,
        message: 'تمت الاستعادة بنجاح',
        customerCount: customerCount,
        operationCount: operationCount,
      );

  factory RestoreResult.failure(String msg) =>
      RestoreResult._(success: false, message: msg);
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  static const String _backupDirName = 'backups';
  static const int _maxBackups = 3;
  static const int _supportedSchema = 1;

  // ═══════════════════════════════════════════════════════════
  // المسارات
  // ═══════════════════════════════════════════════════════════

  Future<Directory?> _getBackupDir() async {
    if (kIsWeb) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, _backupDirName));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // القائمة والقراءة
  // ═══════════════════════════════════════════════════════════

  Future<List<BackupFileInfo>> listBackups() async {
    if (kIsWeb) return [];
    final dir = await _getBackupDir();
    if (dir == null) return [];
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();
      final result = <BackupFileInfo>[];
      for (final file in files) {
        result.add(await _parseBackupFile(file));
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<BackupFileInfo?> getLatestBackup() async {
    final list = await listBackups();
    return list.isEmpty ? null : list.first;
  }

  Future<BackupFileInfo> _parseBackupFile(File file) async {
    final stat = await file.stat();
    int customerCount = 0;
    int operationCount = 0;
    bool isProtection = false;
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile != null) {
        final content = utf8.decode(dataFile.content as List<int>);
        final json = jsonDecode(content) as Map<String, dynamic>;
        customerCount = (json['customers'] as List?)?.length ?? 0;
        operationCount = (json['operations'] as List?)?.length ?? 0;
        isProtection = json['is_protection'] == true;
      }
    } catch (_) {}
    return BackupFileInfo(
      fileName: p.basename(file.path),
      filePath: file.path,
      sizeBytes: stat.size,
      customerCount: customerCount,
      operationCount: operationCount,
      createdAt: stat.modified,
      isProtection: isProtection,
    );
  }

  /// يقرأ ملخص ملف ZIP (بدون استعادة). يُستخدم في شاشة الاستعادة
  /// لعرض التفاصيل قبل تأكيد الاستبدال.
  Future<BackupSummary> readSummary(File file) async {
    try {
      if (!await file.exists()) {
        return BackupSummary.invalid('الملف غير موجود');
      }
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return BackupSummary.invalid('الملف لا يحتوي على data.json');
      }
      final content = utf8.decode(dataFile.content as List<int>);
      final json = jsonDecode(content) as Map<String, dynamic>;

      final schema = json['schema_version'];
      if (schema == null) {
        return BackupSummary.invalid('الملف لا يحتوي على رقم إصدار');
      }
      if (schema != _supportedSchema) {
        return BackupSummary.invalid(
            'إصدار النسخة غير مدعوم (وجد $schema، المتوقع $_supportedSchema)');
      }

      if (json['customers'] is! List || json['operations'] is! List) {
        return BackupSummary.invalid('بيانات الملف ناقصة أو تالفة');
      }

      final createdAtStr = json['created_at'] as String?;
      final createdAt =
          createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

      return BackupSummary(
        valid: true,
        createdAt: createdAt,
        customerCount: (json['customers'] as List).length,
        operationCount: (json['operations'] as List).length,
        storeName: (json['store_name'] as String?) ?? '',
      );
    } catch (e) {
      return BackupSummary.invalid('الملف تالف أو غير صالح');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // الإنشاء
  // ═══════════════════════════════════════════════════════════

  Future<BackupFileInfo?> createBackup({bool isProtection = false}) async {
    if (kIsWeb) return null;
    final dir = await _getBackupDir();
    if (dir == null) return null;

    final ds = DataService.instance;
    final data = <String, dynamic>{
      'schema_version': _supportedSchema,
      'app': 'tajer_amazon',
      'created_at': DateTime.now().toIso8601String(),
      'is_protection': isProtection,
      'store_name': ds.getStoreName(),
      'whatsapp_template': ds.getWhatsAppTemplate(),
      'customers': ds.customers.map(_customerToJson).toList(),
      'operations': ds.operations.map(_operationToJson).toList(),
      'deleted_customers':
          ds.getDeletedCustomers().map(_customerToJson).toList(),
      'deleted_operations':
          ds.getDeletedOperations().map(_operationToJson).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final jsonBytes = utf8.encode(jsonStr);

    final archive = Archive();
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) return null;

    final now = DateTime.now();
    final ts =
        '${now.year}${_p2(now.month)}${_p2(now.day)}_${_p2(now.hour)}${_p2(now.minute)}${_p2(now.second)}';
    final prefix = isProtection ? 'protect' : 'backup';
    final name = 'tajer_${prefix}_$ts.zip';
    final outFile = File(p.join(dir.path, name));
    await outFile.writeAsBytes(zipped);

    final stat = await outFile.stat();
    if (!isProtection) {
      await cleanupOldBackups();
    }
    return BackupFileInfo(
      fileName: name,
      filePath: outFile.path,
      sizeBytes: stat.size,
      customerCount: ds.customers.length,
      operationCount: ds.operations.length,
      createdAt: now,
      isProtection: isProtection,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الحذف والمشاركة
  // ═══════════════════════════════════════════════════════════

  Future<void> deleteBackup(String filePath) async {
    if (kIsWeb) return;
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> shareBackup(String filePath) async {
    if (kIsWeb) return;
    try {
      final file = File(filePath);
      if (!await file.exists()) return;
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'نسخة احتياطية - تاجر أمازون',
      );
    } catch (_) {}
  }

  Future<void> cleanupOldBackups() async {
    if (kIsWeb) return;
    final backups = await listBackups();
    final normal =
        backups.where((b) => !b.isProtection).toList();
    if (normal.length <= _maxBackups) return;
    for (var i = _maxBackups; i < normal.length; i++) {
      await deleteBackup(normal[i].filePath);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // الاستعادة
  // ═══════════════════════════════════════════════════════════

  /// ينسخ ملفاً خارجياً إلى مجلد النسخ (نسخة حماية من الملف المستورد
  /// قبل استخدامه). يرجع مسار الملف الجديد أو null عند الفشل.
  /// ملاحظة: لا نستبدل ملفاً موجوداً — الاسم يحمل timestamp.
  Future<String?> importExternalFile(File file) async {
    if (kIsWeb) return null;
    try {
      if (!await file.exists()) return null;
      final dir = await _getBackupDir();
      if (dir == null) return null;
      final now = DateTime.now();
      final ts =
          '${now.year}${_p2(now.month)}${_p2(now.day)}_${_p2(now.hour)}${_p2(now.minute)}${_p2(now.second)}';
      final name = 'tajer_imported_$ts.zip';
      final dest = File(p.join(dir.path, name));
      final bytes = await file.readAsBytes();
      await dest.writeAsBytes(bytes);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// يستعيد النسخة من ملف. التدفق:
  /// 1. قراءة والتحقق من الملف
  /// 2. إنشاء نسخة حماية تلقائية
  /// 3. تحويل JSON إلى نماذج
  /// 4. استبدال كل البيانات عبر DataService.replaceAllData
  /// 5. إرجاع RestoreResult
  Future<RestoreResult> restoreFromFile(File file) async {
    if (kIsWeb) {
      return RestoreResult.failure('الاستعادة متاحة على التطبيق الأصلي فقط');
    }

    // 1. قراءة والتحقق
    final summary = await readSummary(file);
    if (!summary.valid) {
      return RestoreResult.failure(summary.error ?? 'الملف غير صالح');
    }

    // 2. نسخة حماية
    final protection = await createBackup(isProtection: true);
    if (protection == null) {
      return RestoreResult.failure('تعذّر إنشاء نسخة الحماية قبل الاستعادة');
    }

    // 3. تحويل JSON إلى نماذج
    Map<String, dynamic> json;
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return RestoreResult.failure('الملف لا يحتوي على data.json');
      }
      final content = utf8.decode(dataFile.content as List<int>);
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return RestoreResult.failure('تعذّر قراءة بيانات الملف');
    }

    List<MockCustomer> customers;
    List<Operation> operations;
    List<MockCustomer> deletedCustomers;
    List<Operation> deletedOperations;
    String storeName;
    String whatsappTemplate;

    try {
      customers = (json['customers'] as List)
          .map((e) => _customerFromJson(e as Map<String, dynamic>))
          .toList();
      operations = (json['operations'] as List)
          .map((e) => _operationFromJson(e as Map<String, dynamic>))
          .toList();
      deletedCustomers = ((json['deleted_customers'] as List?) ?? [])
          .map((e) => _customerFromJson(e as Map<String, dynamic>))
          .toList();
      deletedOperations = ((json['deleted_operations'] as List?) ?? [])
          .map((e) => _operationFromJson(e as Map<String, dynamic>))
          .toList();
      storeName = (json['store_name'] as String?) ?? '';
      whatsappTemplate = (json['whatsapp_template'] as String?) ?? '';
    } catch (_) {
      return RestoreResult.failure('بيانات الملف غير متوافقة مع هذا الإصدار');
    }

    // 4. الاستبدال
    final ok = await DataService.instance.replaceAllData(
      customers: customers,
      operations: operations,
      deletedCustomers: deletedCustomers,
      deletedOperations: deletedOperations,
      storeName: storeName,
      whatsappTemplate: whatsappTemplate,
    );

    if (!ok) {
      return RestoreResult.failure('فشل الاستبدال. النسخة الحالية سليمة.');
    }

    return RestoreResult.success(
      customerCount: customers.length,
      operationCount: operations.length,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Serialization
  // ═══════════════════════════════════════════════════════════

  String _p2(int n) => n.toString().padLeft(2, '0');

  Map<String, dynamic> _customerToJson(MockCustomer c) => {
        'id': c.id,
        'primaryName': c.primaryName,
        'aliases': c.aliases,
        'primaryPhone': c.primaryPhone,
        'secondaryPhones': c.secondaryPhones,
        'address': c.address,
        'notes': c.notes,
        'isVip': c.isVip,
      };

  Map<String, dynamic> _operationToJson(Operation o) => {
        'id': o.id,
        'serial': o.serial,
        'customerId': o.customerId,
        'customerName': o.customerName,
        'amount': o.amount,
        'isGift': o.isGift,
        'status': o.status.index,
        'createdAt': o.createdAt.toIso8601String(),
        'deliveredAt': o.deliveredAt?.toIso8601String(),
        'racks': o.racks,
        'batchIndex': o.batchIndex,
        'deletedAt': o.deletedAt?.toIso8601String(),
      };

  MockCustomer _customerFromJson(Map<String, dynamic> j) {
    return MockCustomer(
      id: (j['id'] as String?) ?? '',
      primaryName: (j['primaryName'] as String?) ?? '',
      aliases: ((j['aliases'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      primaryPhone: j['primaryPhone'] as String?,
      secondaryPhones: ((j['secondaryPhones'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      address: j['address'] as String?,
      notes: j['notes'] as String?,
      isVip: (j['isVip'] as bool?) ?? false,
    );
  }

  Operation _operationFromJson(Map<String, dynamic> j) {
    final statusIdx = (j['status'] as int?) ?? 0;
    final safeStatusIdx =
        statusIdx < 0 || statusIdx >= OperationStatus.values.length
            ? 0
            : statusIdx;
    final createdAtStr = (j['createdAt'] as String?) ?? '';
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final deliveredAtStr = j['deliveredAt'] as String?;
    final deletedAtStr = j['deletedAt'] as String?;

    return Operation(
      id: (j['id'] as String?) ?? '',
      serial: (j['serial'] as String?) ?? '',
      customerId: (j['customerId'] as String?) ?? '',
      customerName: (j['customerName'] as String?) ?? '',
      amount: (j['amount'] as int?) ?? 0,
      isGift: (j['isGift'] as bool?) ?? false,
      status: OperationStatus.values[safeStatusIdx],
      createdAt: createdAt,
      deliveredAt:
          deliveredAtStr != null ? DateTime.tryParse(deliveredAtStr) : null,
      racks: ((j['racks'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      batchIndex: (j['batchIndex'] as int?) ?? 0,
      deletedAt:
          deletedAtStr != null ? DateTime.tryParse(deletedAtStr) : null,
    );
  }
}