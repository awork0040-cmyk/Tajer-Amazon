import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../models/operation_model.dart';

enum SortMethod { alphabetical, mostOperations }

class BatchModel {
  final int id;
  final String name;
  final int shelvesCount;
  final DateTime createdAt;

  const BatchModel({
    required this.id,
    required this.name,
    required this.shelvesCount,
    required this.createdAt,
  });

  BatchModel copyWith({String? name, int? shelvesCount}) {
    return BatchModel(
      id: id,
      name: name ?? this.name,
      shelvesCount: shelvesCount ?? this.shelvesCount,
      createdAt: createdAt,
    );
  }
}

/// يمثل بطاقة/باقة طلبات مؤكدة مستقلة لعميل معين
class ConfirmedOrderCardData {
  final String batchKey;
  final String customerId;
  final String customerName;
  final List<Operation> operations;
  final DateTime date;

  const ConfirmedOrderCardData({
    required this.batchKey,
    required this.customerId,
    required this.customerName,
    required this.operations,
    required this.date,
  });

  int get ordersCount => operations.length;
  int get totalAmount => operations.fold<int>(0, (sum, o) => sum + o.amount);
}

/// بيانات البطاقة التي تحتوي عملية معينة (للبحث بالسكنر)
class OperationCardInfo {
  final Operation operation;
  final String customerId;
  final String customerName;
  final String? batchKey; // null إذا كانت العملية غير مؤكدة
  final bool isConfirmed;
  final bool isDelivery;
  final bool isDelivered;

  const OperationCardInfo({
    required this.operation,
    required this.customerId,
    required this.customerName,
    this.batchKey,
    this.isConfirmed = false,
    this.isDelivery = false,
    this.isDelivered = false,
  });
}

class DataService extends ChangeNotifier {
  static final DataService instance = DataService._internal();
  DataService._internal();

  final List<MockCustomer> _customers = [];
  final List<Operation> _operations = [];
  final List<MockCustomer> _deletedCustomers = [];
  final List<Operation> _deletedOperations = [];
  final List<BatchModel> _batches = [];
  final Map<String, OperationStatus> _previousStatuses = {};

  /// يربط كل عملية مؤكدة برقم باقة مؤكدة حتى تبقى الباقات المنفصلة مستقلة
  final Map<String, String> _operationBatchMap = {};
  int _batchCounter = 0;

  String _storeName = 'متجري';
  String _whatsappTemplate = 'مرحباً [اسم العميل]...';
  int _shelvesPerBatch = 50;
  SortMethod _sortMethod = SortMethod.alphabetical;
  int _serialCounter = 1050;
  int _idCounter = 100;
  bool _initialized = false;
  static const int _maxBatches = 5;

  // حالة واجهة (in-memory فقط، لا تُحفظ)
  int _lastDeliverySubTab = 0;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _seedData();
    _seedBatches();
  }

  void _seedBatches() {
    _batches.add(BatchModel(
      id: 0,
      name: 'الوجبة الأولى',
      shelvesCount: _shelvesPerBatch,
      createdAt: DateTime.now(),
    ));
  }

  void _seedData() {
    // ═══════════════════════════════════════════════════════════
    // عملاء تجريبيون
    // ═══════════════════════════════════════════════════════════
    final c1 = MockCustomer(id: 'c1', primaryName: 'أحمد علي', aliases: const ['أبو علي'], primaryPhone: '07801234567', isVip: true);
    final c2 = MockCustomer(id: 'c2', primaryName: 'حميدة سالم');
    final c3 = MockCustomer(id: 'c3', primaryName: 'محمد كريم', aliases: const ['محمد'], primaryPhone: '07709876543');
    final c4 = MockCustomer(id: 'c4', primaryName: 'زينب حسن', aliases: const ['أم حسين'], isVip: true);
    final c5 = MockCustomer(id: 'c5', primaryName: 'علي جاسم', primaryPhone: '07811111111');
    final c6 = MockCustomer(id: 'c6', primaryName: 'فاطمة عبد', primaryPhone: '07701112233');
    final c7 = MockCustomer(id: 'c7', primaryName: 'حسين كاظم', primaryPhone: '07803334455');
    final c8 = MockCustomer(id: 'c8', primaryName: 'هدى حسين');
    final c9 = MockCustomer(id: 'c9', primaryName: 'رقية عبد', aliases: const ['أم عبد']);
    final c10 = MockCustomer(id: 'c10', primaryName: 'كرار محمود', isVip: true);

    _customers.addAll([c1, c2, c3, c4, c5, c6, c7, c8, c9, c10]);

    // ═══════════════════════════════════════════════════════════
    // سيناريوهات غير مؤكدة
    // ═══════════════════════════════════════════════════════════
    // c1: عميل عنده غير مؤكدة فقط (بدون مؤكدة) — سيناريو عادي
    _addSeedOp(c1, 25000, OperationStatus.unconfirmed);
    _addSeedOp(c1, 15000, OperationStatus.unconfirmed);

    // c2: عميل عنده غير مؤكدة فقط
    _addSeedOp(c2, 30000, OperationStatus.unconfirmed);

    // c6: عميل عنده غير مؤكدة + مؤكدة (سيناريو دمج مختلط)
    _addSeedOp(c6, 12000, OperationStatus.unconfirmed);
    _addSeedOp(c6, 8000, OperationStatus.unconfirmed);
    _addSeedOp(c6, 20000, OperationStatus.confirmed);

    // c7: عميل عنده غير مؤكدة فقط
    _addSeedOp(c7, 8000, OperationStatus.unconfirmed);

    // ═══════════════════════════════════════════════════════════
    // سيناريوهات مؤكدة
    // ═══════════════════════════════════════════════════════════
    // c3: عميل عنده بطاقة مؤكدة واحدة
    _addSeedOp(c3, 15000, OperationStatus.confirmed);
    _addSeedOp(c3, 10000, OperationStatus.confirmed);

    // c8: عميل عنده بطاقتان مؤكدتان منفصلتان (سيناريو دمج)
    _addSeedOp(c8, 18000, OperationStatus.confirmed);
    _addSeedOp(c8, 22000, OperationStatus.confirmed);

    // c10: عميل عنده بطاقة مؤكدة + بطاقة غير مؤكدة (سيناريو دمج مختلط)
    _addSeedOp(c10, 35000, OperationStatus.confirmed);
    _addSeedOp(c10, 5000, OperationStatus.unconfirmed);

    // ═══════════════════════════════════════════════════════════
    // سيناريوهات توصيل
    // ═══════════════════════════════════════════════════════════
    // c4: عميل عنده طلب جاري التوصيل
    _addSeedOp(c4, 60000, OperationStatus.outForDelivery);

    // c9: عميل عنده طلبات تم التوصيل
    _addSeedOp(c9, 15000, OperationStatus.delivered);

    // c5: عميل عنده طلب تم التوصيل
    _addSeedOp(c5, 30000, OperationStatus.delivered);

    for (final c in _customers) {
      _recalculateStatsForCustomer(c.id);
    }
  }

  void _addSeedOp(MockCustomer customer, int amount, OperationStatus status) {
    _serialCounter++;
    _idCounter++;
    final opId = 'op$_idCounter';
    final createdAt = DateTime.now().subtract(Duration(minutes: _idCounter * 10));
    _operations.add(Operation(
      id: opId,
      serial: 'TA1-$_serialCounter',
      customerId: customer.id,
      customerName: customer.primaryName,
      amount: amount,
      status: status,
      createdAt: createdAt,
      deliveredAt: status == OperationStatus.delivered ? DateTime.now() : null,
    ));
    if (status == OperationStatus.confirmed) {
      _operationBatchMap[opId] = _createBatchKey(customer.id, createdAt);
    }
  }

  String _createBatchKey(String customerId, DateTime stamp) {
    _batchCounter++;
    return '${customerId}_batch_${_batchCounter}_${stamp.microsecondsSinceEpoch}';
  }

  List<MockCustomer> get customers => List.unmodifiable(_customers);
  List<Operation> get operations => List.unmodifiable(_operations);
  List<BatchModel> get batches => List.unmodifiable(_batches);
  int get shelvesPerBatch => _shelvesPerBatch;
  SortMethod get sortMethod => _sortMethod;
  int get maxBatches => _maxBatches;
  List<MockCustomer> getDeletedCustomers() => List.unmodifiable(_deletedCustomers);
  List<Operation> getDeletedOperations() => List.unmodifiable(_deletedOperations);

  int get lastDeliverySubTab => _lastDeliverySubTab;
  set lastDeliverySubTab(int v) {
    if (v == 0 || v == 1) _lastDeliverySubTab = v;
  }

  MockCustomer? getCustomerById(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<MockCustomer> getCustomersByRecency() {
    final sorted = List<MockCustomer>.from(_customers);
    sorted.sort((a, b) {
      final aTime = a.lastUsedAt;
      final bTime = b.lastUsedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  Operation? getOperationBySerial(String serial) {
    for (final o in _operations) {
      if (o.serial == serial) return o;
    }
    for (final o in _deletedOperations) {
      if (o.serial == serial) return o;
    }
    return null;
  }

  /// يحوّل عملية إلى معلومات البطاقة التي تحتويها (للبحث بالسكنر).
  OperationCardInfo? getOperationCardInfo(String serial) {
    final op = getOperationBySerial(serial);
    if (op == null || op.status == OperationStatus.deleted) return null;

    final customer = getCustomerById(op.customerId);
    final customerName = customer?.primaryName ?? op.customerName;

    if (op.status == OperationStatus.confirmed) {
      final batchKey = _operationBatchMap[op.id] ?? '${op.customerId}_default_confirmed';
      return OperationCardInfo(
        operation: op,
        customerId: op.customerId,
        customerName: customerName,
        batchKey: batchKey,
        isConfirmed: true,
      );
    } else if (op.status == OperationStatus.unconfirmed) {
      return OperationCardInfo(
        operation: op,
        customerId: op.customerId,
        customerName: customerName,
        isConfirmed: false,
      );
    } else if (op.status == OperationStatus.outForDelivery) {
      return OperationCardInfo(
        operation: op,
        customerId: op.customerId,
        customerName: customerName,
        isDelivery: true,
      );
    } else if (op.status == OperationStatus.delivered) {
      return OperationCardInfo(
        operation: op,
        customerId: op.customerId,
        customerName: customerName,
        isDelivered: true,
      );
    }
    return null;
  }

  List<Operation> getOperationsForCustomer(String customerId) {
    return _operations.where((o) => o.customerId == customerId).toList();
  }

  List<Operation> getDisplayableOperationsForCustomer(String customerId) {
    return _operations
        .where((o) =>
            o.customerId == customerId &&
            (o.status == OperationStatus.unconfirmed || o.status == OperationStatus.confirmed))
        .toList();
  }

  List<Operation> getUnconfirmedOperations() =>
      _operations.where((o) => o.status == OperationStatus.unconfirmed).toList();

  List<Operation> getConfirmedOperations() =>
      _operations.where((o) => o.status == OperationStatus.confirmed).toList();

  List<Operation> getOutForDeliveryOperations() =>
      _operations.where((o) => o.status == OperationStatus.outForDelivery).toList();

  List<Operation> getDeliveredOperations() =>
      _operations.where((o) => o.status == OperationStatus.delivered).toList();

  DateTime? getFirstUnconfirmedDateForCustomer(String customerId) {
    final unconfirmed = _operations
        .where((o) => o.customerId == customerId && o.status == OperationStatus.unconfirmed)
        .toList();
    if (unconfirmed.isEmpty) return null;
    unconfirmed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return unconfirmed.first.createdAt;
  }

  List<ConfirmedOrderCardData> getConfirmedCardsForCustomer(String customerId) {
    final ops = _operations
        .where((o) => o.customerId == customerId && o.status == OperationStatus.confirmed)
        .toList();
    if (ops.isEmpty) return const [];

    final customer = getCustomerById(customerId);
    final custName = customer?.primaryName ?? ops.first.customerName;

    final Map<String, List<Operation>> grouped = {};
    for (final op in ops) {
      final key = _operationBatchMap[op.id] ?? '${customerId}_default_confirmed';
      grouped.putIfAbsent(key, () => []).add(op);
    }

    final cards = grouped.entries.map((entry) {
      final list = entry.value;
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ConfirmedOrderCardData(
        batchKey: entry.key,
        customerId: customerId,
        customerName: custName,
        operations: list,
        date: list.first.createdAt,
      );
    }).toList();

    cards.sort((a, b) => b.date.compareTo(a.date));
    return cards;
  }

  bool hasConfirmedOrders(String customerId) {
    return _operations.any((o) => o.customerId == customerId && o.status == OperationStatus.confirmed);
  }

  /// دمج مجموعة بطاقات مؤكدة معاً في بطاقة واحدة.
  /// [primaryBatchKey] هي البطاقة الأساسية التي ستستقبل بقية البطاقات.
  void mergeConfirmedCardsInto(String customerId, String primaryBatchKey, List<String> otherBatchKeys) {
    if (otherBatchKeys.isEmpty) return;
    bool changed = false;
    for (final op in _operations) {
      if (op.customerId == customerId && op.status == OperationStatus.confirmed) {
        final opKey = _operationBatchMap[op.id] ?? '${customerId}_default_confirmed';
        if (otherBatchKeys.contains(opKey)) {
          _operationBatchMap[op.id] = primaryBatchKey;
          changed = true;
        }
      }
    }
    if (changed) {
      _recalculateStatsForCustomer(customerId);
      notifyListeners();
    }
  }

  void mergeSpecificConfirmedBatch(String customerId, String batchKey) {
    bool changed = false;
    for (int i = 0; i < _operations.length; i++) {
      final op = _operations[i];
      if (op.customerId == customerId && op.status == OperationStatus.confirmed) {
        final opKey = _operationBatchMap[op.id] ?? '${customerId}_default_confirmed';
        if (opKey == batchKey) {
          _operations[i] = op.copyWith(status: OperationStatus.unconfirmed);
          _operationBatchMap.remove(op.id);
          changed = true;
        }
      }
    }
    if (changed) {
      _recalculateStatsForCustomer(customerId);
      notifyListeners();
    }
  }

  void mergeCustomerOperations(String customerId) {
    bool changed = false;
    for (int i = 0; i < _operations.length; i++) {
      if (_operations[i].customerId == customerId && _operations[i].status == OperationStatus.confirmed) {
        _operations[i] = _operations[i].copyWith(status: OperationStatus.unconfirmed);
        _operationBatchMap.remove(_operations[i].id);
        changed = true;
      }
    }
    if (changed) {
      _recalculateStatsForCustomer(customerId);
      notifyListeners();
    }
  }

  void confirmOperation(String opId) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations[idx];
    final batchKey = _createBatchKey(op.customerId, DateTime.now());
    _operations[idx] = op.copyWith(status: OperationStatus.confirmed);
    _operationBatchMap[op.id] = batchKey;
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void confirmAllUnconfirmedForCustomer(String customerId) {
    final batchKey = _createBatchKey(customerId, DateTime.now());
    bool changed = false;
    for (int i = 0; i < _operations.length; i++) {
      if (_operations[i].customerId == customerId && _operations[i].status == OperationStatus.unconfirmed) {
        _operations[i] = _operations[i].copyWith(status: OperationStatus.confirmed);
        _operationBatchMap[_operations[i].id] = batchKey;
        changed = true;
      }
    }
    if (changed) {
      _recalculateStatsForCustomer(customerId);
      notifyListeners();
    }
  }

  void unconfirmOperation(String opId) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations[idx];
    _operations[idx] = op.copyWith(status: OperationStatus.unconfirmed);
    _operationBatchMap.remove(op.id);
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void updateOperationStatus(String opId, OperationStatus newStatus) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations[idx];
    if (newStatus == OperationStatus.confirmed && op.status != OperationStatus.confirmed) {
      _operationBatchMap[op.id] = _createBatchKey(op.customerId, DateTime.now());
    } else if (newStatus != OperationStatus.confirmed) {
      _operationBatchMap.remove(op.id);
    }
    _operations[idx] = op.copyWith(
      status: newStatus,
      deliveredAt: newStatus == OperationStatus.delivered ? DateTime.now() : op.deliveredAt,
    );
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void addOperation({required String customerId, required int amount, bool isGift = false}) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _serialCounter++;
    _idCounter++;
    _operations.add(Operation(
      id: 'op$_idCounter',
      serial: 'TA1-$_serialCounter',
      customerId: customerId,
      customerName: _customers[idx].primaryName,
      amount: amount,
      isGift: isGift,
      status: OperationStatus.unconfirmed,
      createdAt: DateTime.now(),
    ));
    _customers[idx] = _customers[idx].copyWith(lastUsedAt: DateTime.now());
    _recalculateStatsForCustomer(customerId);
    notifyListeners();
  }

  void deleteOperation(String opId) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations.removeAt(idx);
    _previousStatuses[op.id] = op.status;
    _operationBatchMap.remove(op.id);
    _deletedOperations.add(op.copyWith(status: OperationStatus.deleted, deletedAt: DateTime.now()));
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void cancelDeliveryOrder(String opId) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations.removeAt(idx);
    _previousStatuses[op.id] = op.status;
    _operationBatchMap.remove(op.id);
    _deletedOperations.add(op.copyWith(status: OperationStatus.deleted, deletedAt: DateTime.now()));
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void updateOperation(String oldOpId, {required int newAmount, String? newCustomerId}) {
    final idx = _operations.indexWhere((o) => o.id == oldOpId);
    if (idx == -1) return;
    final oldOp = _operations.removeAt(idx);
    final custId = newCustomerId ?? oldOp.customerId;
    final custIdx = _customers.indexWhere((c) => c.id == custId);
    final custName = custIdx >= 0 ? _customers[custIdx].primaryName : oldOp.customerName;

    _operations.add(Operation(
      id: oldOp.id,
      serial: oldOp.serial,
      customerId: custId,
      customerName: custName,
      amount: newAmount,
      isGift: oldOp.isGift,
      status: oldOp.status,
      createdAt: oldOp.createdAt,
      racks: oldOp.racks,
      batchIndex: oldOp.batchIndex,
    ));
    _recalculateStatsForCustomer(oldOp.customerId);
    if (custId != oldOp.customerId) _recalculateStatsForCustomer(custId);
    notifyListeners();
  }

  List<Operation> getRecentOperations() {
    final now = DateTime.now();
    return _operations
        .where((o) => now.difference(o.createdAt).inHours < 24)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool restoreOperation(String opId) {
    final idx = _deletedOperations.indexWhere((o) => o.id == opId);
    if (idx == -1) return false;
    final op = _deletedOperations[idx];
    if (getCustomerById(op.customerId) == null) return false;
    _deletedOperations.removeAt(idx);
    final previous = _previousStatuses.remove(op.id) ?? OperationStatus.unconfirmed;
    if (previous == OperationStatus.confirmed) {
      _operationBatchMap[op.id] = _createBatchKey(op.customerId, DateTime.now());
    }
    _operations.add(op.copyWith(status: previous, deletedAt: null));
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
    return true;
  }

  bool restoreCustomer(String customerId) {
    final idx = _deletedCustomers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return false;
    final customer = _deletedCustomers.removeAt(idx);
    _customers.add(customer);
    for (int i = _deletedOperations.length - 1; i >= 0; i--) {
      if (_deletedOperations[i].customerId == customerId) {
        final op = _deletedOperations.removeAt(i);
        final previous = _previousStatuses.remove(op.id) ?? OperationStatus.unconfirmed;
        if (previous == OperationStatus.confirmed) {
          _operationBatchMap[op.id] = _createBatchKey(op.customerId, DateTime.now());
        }
        _operations.add(op.copyWith(status: previous, deletedAt: null));
      }
    }
    _recalculateStatsForCustomer(customerId);
    notifyListeners();
    return true;
  }

  void permanentlyDeleteOperation(String opId) {
    final idx = _deletedOperations.indexWhere((o) => o.id == opId);
    if (idx != -1) {
      final op = _deletedOperations.removeAt(idx);
      _previousStatuses.remove(op.id);
      _operationBatchMap.remove(op.id);
      notifyListeners();
    }
  }

  void permanentlyDeleteCustomer(String customerId) {
    final idx = _deletedCustomers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      _deletedCustomers.removeAt(idx);
      for (int i = _deletedOperations.length - 1; i >= 0; i--) {
        if (_deletedOperations[i].customerId == customerId) {
          _operationBatchMap.remove(_deletedOperations[i].id);
          _deletedOperations.removeAt(i);
        }
      }
      notifyListeners();
    }
  }

  void _recalculateStatsForCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final ops = _operations.where((o) => o.customerId == customerId).toList();
    final pending = ops
        .where((o) => o.status != OperationStatus.delivered && o.status != OperationStatus.deleted)
        .toList();

    _customers[idx] = _customers[idx].copyWith(
      totalOps: ops.length,
      totalAmount: ops.fold<int>(0, (sum, o) => sum + o.amount),
      pendingOps: pending.length,
      pendingAmount: pending.fold<int>(0, (sum, o) => sum + o.amount),
    );
  }

  String normalizeArabic(String input) {
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

  bool isPrimaryNameTaken(String name, {String? excludeCustomerId}) {
    final norm = normalizeArabic(name);
    if (norm.isEmpty) return false;
    for (final c in _customers) {
      if (excludeCustomerId != null && c.id == excludeCustomerId) continue;
      if (normalizeArabic(c.primaryName) == norm) return true;
    }
    return false;
  }

  List<MockCustomer> searchCustomers(String query, {bool onlyVip = false}) {
    final q = normalizeArabic(query);
    return _customers.where((c) {
      if (onlyVip && !c.isVip) return false;
      if (q.isEmpty) return true;
      final name = normalizeArabic(c.primaryName);
      final aliases = c.aliases.map((a) => normalizeArabic(a)).join(' ');
      return name.contains(q) || aliases.contains(q) || (c.primaryPhone ?? '').contains(query.trim());
    }).toList();
  }

  List<MockCustomer> searchCustomersByRecency(String query, {bool onlyVip = false}) {
    final results = searchCustomers(query, onlyVip: onlyVip);
    final q = normalizeArabic(query);

    int matchRank(MockCustomer c) {
      if (q.isEmpty) return 0;
      final name = normalizeArabic(c.primaryName);
      if (name.startsWith(q)) return 0;
      if (name.contains(q)) return 1;
      return 2;
    }

    results.sort((a, b) {
      final ra = matchRank(a);
      final rb = matchRank(b);
      if (ra != rb) return ra.compareTo(rb);

      final aTime = a.lastUsedAt;
      final bTime = b.lastUsedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return results;
  }

  String getStoreName() => _storeName;
  void setStoreName(String name) {
    if (name.trim().isEmpty || name.trim().length > 50) return;
    _storeName = name.trim();
    notifyListeners();
  }

  String getWhatsAppTemplate() => _whatsappTemplate;
  void setWhatsAppTemplate(String template) {
    _whatsappTemplate = template;
    notifyListeners();
  }

  void addCustomer(MockCustomer c) {
    _customers.add(c.copyWith(lastUsedAt: DateTime.now()));
    notifyListeners();
  }

  void updateCustomer(MockCustomer c) {
    final idx = _customers.indexWhere((x) => x.id == c.id);
    if (idx == -1) return;
    _customers[idx] = c.copyWith(lastUsedAt: DateTime.now());
    notifyListeners();
  }

  void toggleVip(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _customers[idx] = _customers[idx].copyWith(isVip: !_customers[idx].isVip);
    notifyListeners();
  }

  void deleteCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final customer = _customers.removeAt(idx);
    _deletedCustomers.add(customer);
    for (int i = _operations.length - 1; i >= 0; i--) {
      if (_operations[i].customerId == customerId) {
        final op = _operations.removeAt(i);
        _previousStatuses[op.id] = op.status;
        _operationBatchMap.remove(op.id);
        _deletedOperations.add(op.copyWith(status: OperationStatus.deleted, deletedAt: DateTime.now()));
      }
    }
    notifyListeners();
  }

  MockCustomer? getCustomerAtShelf(int batchId, int shelfNumber) {
    for (final c in _customers) {
      if (c.assignedBatch == batchId && c.shelfNumbers.contains(shelfNumber)) return c;
    }
    return null;
  }

  Map<int, String> getOccupiedShelves(int batchId) {
    final map = <int, String>{};
    for (final c in _customers) {
      if (c.assignedBatch == batchId) {
        for (final s in c.shelfNumbers) {
          map[s] = c.primaryName;
        }
      }
    }
    return map;
  }

  List<String> assignShelf(String customerId, int batchId, int shelfNumber) {
    final displaced = <String>[];
    for (int i = 0; i < _customers.length; i++) {
      final c = _customers[i];
      if (c.id == customerId) continue;
      if (c.shelfNumbers.contains(shelfNumber) && c.assignedBatch == batchId) {
        displaced.add(c.primaryName);
        _customers[i] = c.copyWith(shelfNumbers: const [], clearAssignedBatch: true);
      }
    }
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final c = _customers[idx];
      final newShelves = [...c.shelfNumbers];
      if (!newShelves.contains(shelfNumber)) newShelves.add(shelfNumber);
      _customers[idx] = c.copyWith(shelfNumbers: newShelves..sort(), assignedBatch: batchId);
    }
    notifyListeners();
    return displaced;
  }

  void removeShelf(String customerId, int shelfNumber) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final c = _customers[idx];
    final newShelves = c.shelfNumbers.where((s) => s != shelfNumber).toList();
    _customers[idx] = c.copyWith(shelfNumbers: newShelves, clearAssignedBatch: newShelves.isEmpty);
    notifyListeners();
  }

  BatchModel? addBatch({String? name}) {
    if (_batches.length >= _maxBatches) return null;
    final newId = _batches.isEmpty ? 0 : _batches.last.id + 1;
    final batch = BatchModel(
      id: newId,
      name: name ?? 'الوجبة ${newId + 1}',
      shelvesCount: _shelvesPerBatch,
      createdAt: DateTime.now(),
    );
    _batches.add(batch);
    notifyListeners();
    return batch;
  }

  int getVisibleOpsCount(String customerId) {
    return _operations
        .where((o) =>
            o.customerId == customerId &&
            (o.status == OperationStatus.unconfirmed || o.status == OperationStatus.confirmed))
        .length;
  }

  void autoAssignUnassigned() {
    final unassigned = _customers
        .where((c) => c.shelfNumbers.isEmpty && !c.isPinned && _hasVisibleOps(c.id))
        .toList();
    if (unassigned.isEmpty) return;
    for (final c in unassigned) {
      for (final batch in _batches) {
        final occupied = getOccupiedShelves(batch.id);
        for (int s = 1; s <= batch.shelvesCount; s++) {
          if (!occupied.containsKey(s)) {
            final idx = _customers.indexWhere((x) => x.id == c.id);
            if (idx != -1) {
              _customers[idx] = _customers[idx].copyWith(shelfNumbers: [s], assignedBatch: batch.id);
            }
            break;
          }
        }
      }
    }
    notifyListeners();
  }

  void fillGaps() {
    for (int i = 0; i < _customers.length; i++) {
      final c = _customers[i];
      if (c.isPinned || c.shelfNumbers.isEmpty || c.assignedBatch == null) continue;
      final currentShelf = c.shelfNumbers.first;
      final occupied = getOccupiedShelves(c.assignedBatch!);
      for (int s = 1; s < currentShelf; s++) {
        if (!occupied.containsKey(s)) {
          _customers[i] = c.copyWith(shelfNumbers: [s]);
          break;
        }
      }
    }
    autoAssignUnassigned();
    notifyListeners();
  }

  void reorderFullNonPinned() {
    for (int i = 0; i < _customers.length; i++) {
      if (!_customers[i].isPinned) {
        _customers[i] = _customers[i].copyWith(shelfNumbers: const [], clearAssignedBatch: true);
      }
    }
    autoAssignUnassigned();
    notifyListeners();
  }

  void reorderFullAll() {
    for (int i = 0; i < _customers.length; i++) {
      _customers[i] = _customers[i].copyWith(shelfNumbers: const [], clearAssignedBatch: true, isPinned: false);
    }
    autoAssignUnassigned();
    notifyListeners();
  }

  void resetDistribution() {
    for (int i = 0; i < _customers.length; i++) {
      _customers[i] = _customers[i].copyWith(shelfNumbers: const [], clearAssignedBatch: true, isPinned: false);
    }
    notifyListeners();
  }

  void setShelvesPerBatch(int count) {
    if (count >= 1) {
      _shelvesPerBatch = count;
      notifyListeners();
    }
  }

  void setSortMethod(SortMethod method) {
    _sortMethod = method;
    notifyListeners();
  }

  List<MockCustomer> getSortingCustomers() {
    final visible = _customers.where((c) => _hasVisibleOps(c.id)).toList();
    visible.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aHas = a.shelfNumbers.isNotEmpty;
      final bHas = b.shelfNumbers.isNotEmpty;
      if (aHas && bHas) return a.shelfNumbers.first.compareTo(b.shelfNumbers.first);
      if (aHas && !bHas) return -1;
      if (!aHas && bHas) return 1;
      return 0;
    });
    return visible;
  }

  void pinCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      _customers[idx] = _customers[idx].copyWith(isPinned: true);
      notifyListeners();
    }
  }

  void unpinCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      _customers[idx] = _customers[idx].copyWith(isPinned: false);
      notifyListeners();
    }
  }

  bool _hasVisibleOps(String customerId) => _operations.any((o) =>
      o.customerId == customerId &&
      (o.status == OperationStatus.unconfirmed || o.status == OperationStatus.confirmed));

  Future<bool> replaceAllData({
    required List<MockCustomer> customers,
    required List<Operation> operations,
    required List<MockCustomer> deletedCustomers,
    required List<Operation> deletedOperations,
    required String storeName,
    required String whatsappTemplate,
  }) async {
    _customers.clear();
    _customers.addAll(customers);
    _operations.clear();
    _operations.addAll(operations);
    _deletedCustomers.clear();
    _deletedCustomers.addAll(deletedCustomers);
    _deletedOperations.clear();
    _deletedOperations.addAll(deletedOperations);
    _operationBatchMap.clear();
    for (final op in _operations) {
      if (op.status == OperationStatus.confirmed) {
        _operationBatchMap[op.id] = _createBatchKey(op.customerId, op.createdAt);
      }
    }
    if (storeName.isNotEmpty) _storeName = storeName;
    if (whatsappTemplate.isNotEmpty) _whatsappTemplate = whatsappTemplate;
    for (final c in _customers) {
      _recalculateStatsForCustomer(c.id);
    }
    notifyListeners();
    return true;
  }
}