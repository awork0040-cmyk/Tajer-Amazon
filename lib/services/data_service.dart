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

class DataService extends ChangeNotifier {
  static final DataService instance = DataService._internal();
  DataService._internal();

  final List<MockCustomer> _customers = [];
  final List<Operation> _operations = [];
  final List<MockCustomer> _deletedCustomers = [];
  final List<Operation> _deletedOperations = [];
  final List<BatchModel> _batches = [];
  final Map<String, OperationStatus> _previousStatuses = {};

  String _storeName = 'متجري';
  String _whatsappTemplate =
      'مرحباً [اسم العميل]،\n'
      'شكراً لطلبك من [اسم المتجر].\n'
      'المبلغ الإجمالي: [المبلغ] د.ع.\n'
      'عدد الطلبات: [عدد الطلبات].\n'
      'التاريخ: [التاريخ].';

  int _shelvesPerBatch = 50;
  SortMethod _sortMethod = SortMethod.alphabetical;
  int _serialCounter = 1050;
  int _idCounter = 100;
  bool _initialized = false;

  static const int _maxBatches = 5;

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
    final c1 = MockCustomer(id: 'c1', primaryName: 'أحمد علي', aliases: const ['أبو علي'], primaryPhone: '07801234567', isVip: true);
    final c2 = MockCustomer(id: 'c2', primaryName: 'حميدة سالم');
    final c3 = MockCustomer(id: 'c3', primaryName: 'محمد كريم', aliases: const ['محمد'], primaryPhone: '07709876543');
    final c4 = MockCustomer(id: 'c4', primaryName: 'زينب حسن', aliases: const ['أم حسين'], isVip: true);
    final c5 = MockCustomer(id: 'c5', primaryName: 'علي جاسم', primaryPhone: '07811111111');
    final c6 = MockCustomer(id: 'c6', primaryName: 'فاطمة عبد', aliases: const ['فطوم'], primaryPhone: '07811112222');
    final c7 = MockCustomer(id: 'c7', primaryName: 'حسين كاظم', primaryPhone: '07811113333');
    final c8 = MockCustomer(id: 'c8', primaryName: 'مريم صالح');
    final c9 = MockCustomer(id: 'c9', primaryName: 'كرار مهدي', primaryPhone: '07811114444');
    final c10 = MockCustomer(id: 'c10', primaryName: 'نور الهدى', aliases: const ['نور']);
    final c11 = MockCustomer(id: 'c11', primaryName: 'حسن علي', primaryPhone: '07811115555', isVip: true);
    final c12 = MockCustomer(id: 'c12', primaryName: 'زهراء محمد');
    final c13 = MockCustomer(id: 'c13', primaryName: 'عباس كريم', primaryPhone: '07811116666');
    final c14 = MockCustomer(id: 'c14', primaryName: 'هدى حسين');
    final c15 = MockCustomer(id: 'c15', primaryName: 'مصطفى صالح', primaryPhone: '07811117777');
    final c16 = MockCustomer(id: 'c16', primaryName: 'رقية عبد');
    final c17 = MockCustomer(id: 'c17', primaryName: 'يوسف جاسم', primaryPhone: '07811118888');
    final c18 = MockCustomer(id: 'c18', primaryName: 'سجاد مهدي');
    final c19 = MockCustomer(id: 'c19', primaryName: 'زينب علي', primaryPhone: '07811119999');
    final c20 = MockCustomer(id: 'c20', primaryName: 'أحمد حسن');

    _customers.addAll([c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20]);

    _addSeedOp(c1, 25000, OperationStatus.unconfirmed);
    _addSeedOp(c1, 15000, OperationStatus.unconfirmed);
    _addSeedOp(c2, 30000, OperationStatus.unconfirmed);
    _addSeedOp(c4, 60000, OperationStatus.unconfirmed);
    _addSeedOp(c6, 12000, OperationStatus.unconfirmed);
    _addSeedOp(c7, 8000, OperationStatus.unconfirmed);
    _addSeedOp(c9, 22000, OperationStatus.unconfirmed);
    _addSeedOp(c12, 18000, OperationStatus.unconfirmed);

    _addSeedOp(c3, 15000, OperationStatus.confirmed);
    _addSeedOp(c3, 10000, OperationStatus.confirmed);
    _addSeedOp(c5, 45000, OperationStatus.confirmed);
    _addSeedOp(c1, 20000, OperationStatus.confirmed);
    _addSeedOp(c8, 35000, OperationStatus.confirmed);
    _addSeedOp(c10, 28000, OperationStatus.confirmed);
    _addSeedOp(c13, 50000, OperationStatus.confirmed);
    _addSeedOp(c15, 32000, OperationStatus.confirmed);

    _addSeedOp(c4, 60000, OperationStatus.delivered);
    _addSeedOp(c5, 30000, OperationStatus.delivered);
    _addSeedOp(c2, 25000, OperationStatus.delivered);
    _addSeedOp(c11, 40000, OperationStatus.delivered);
    _addSeedOp(c14, 20000, OperationStatus.delivered);
    _addSeedOp(c16, 15000, OperationStatus.delivered);

    for (final c in _customers) {
      _recalculateStatsForCustomer(c.id);
    }
  }

  void _addSeedOp(MockCustomer customer, int amount, OperationStatus status) {
    _serialCounter++;
    _idCounter++;
    _operations.add(Operation(
      id: 'op$_idCounter',
      serial: 'TA1-$_serialCounter',
      customerId: customer.id,
      customerName: customer.primaryName,
      amount: amount,
      status: status,
      createdAt: DateTime.now().subtract(Duration(minutes: _idCounter * 10)),
      deliveredAt: status == OperationStatus.delivered
          ? DateTime.now().subtract(Duration(hours: _idCounter))
          : null,
    ));
  }

  List<MockCustomer> get customers => List.unmodifiable(_customers);
  List<Operation> get operations => List.unmodifiable(_operations);
  List<BatchModel> get batches => List.unmodifiable(_batches);
  int get shelvesPerBatch => _shelvesPerBatch;
  SortMethod get sortMethod => _sortMethod;
  int get maxBatches => _maxBatches;

  List<MockCustomer> getDeletedCustomers() => List.unmodifiable(_deletedCustomers);
  List<Operation> getDeletedOperations() => List.unmodifiable(_deletedOperations);

  MockCustomer? getCustomerById(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Operation? getOperationById(String id) {
    for (final o in _operations) {
      if (o.id == id) return o;
    }
    return null;
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

  List<Operation> getOperationsForCustomer(String customerId) {
    return _operations.where((o) => o.customerId == customerId).toList();
  }

  List<Operation> getDisplayableOperationsForCustomer(String customerId) {
    return _operations
        .where((o) =>
            o.customerId == customerId &&
            (o.status == OperationStatus.unconfirmed ||
                o.status == OperationStatus.confirmed))
        .toList();
  }

  List<Operation> getUnconfirmedOperations() =>
      _operations.where((o) => o.status == OperationStatus.unconfirmed).toList();

  List<Operation> getConfirmedOperations() =>
      _operations.where((o) => o.status == OperationStatus.confirmed).toList();

  List<Operation> getDeliveredOperations() =>
      _operations.where((o) => o.status == OperationStatus.delivered).toList();

  List<Operation> getRecentOperations() {
    final now = DateTime.now();
    final list = _operations.where((o) => now.difference(o.createdAt).inHours < 24).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<MockCustomer> getCustomersByRecency() {
    final used = _customers.where((c) => c.lastUsedAt != null).toList();
    final fresh = _customers.where((c) => c.lastUsedAt == null).toList();
    used.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    fresh.sort((a, b) {
      final na = int.tryParse(a.id.replaceFirst('c', '')) ?? 0;
      final nb = int.tryParse(b.id.replaceFirst('c', '')) ?? 0;
      return na.compareTo(nb);
    });
    return [...used, ...fresh];
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

  void updateOperationStatus(String opId, OperationStatus newStatus) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations[idx];
    _operations[idx] = op.copyWith(
      status: newStatus,
      deliveredAt: newStatus == OperationStatus.delivered ? DateTime.now() : op.deliveredAt,
    );
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void deleteOperation(String opId) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _operations.removeAt(idx);
    _previousStatuses[op.id] = op.status;
    _deletedOperations.add(op.copyWith(status: OperationStatus.deleted, deletedAt: DateTime.now()));
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
  }

  void updateOperation(String oldOpId, {required int newAmount, String? newCustomerId}) {
    final idx = _operations.indexWhere((o) => o.id == oldOpId);
    if (idx == -1) return;
    final oldOp = _operations.removeAt(idx);
    _serialCounter++;
    _idCounter++;
    final custId = newCustomerId ?? oldOp.customerId;
    final custIdx = _customers.indexWhere((c) => c.id == custId);
    final custName = custIdx >= 0 ? _customers[custIdx].primaryName : oldOp.customerName;

    _operations.add(Operation(
      id: 'op$_idCounter',
      serial: 'TA1-$_serialCounter',
      customerId: custId,
      customerName: custName,
      amount: newAmount,
      isGift: oldOp.isGift,
      status: oldOp.status,
      createdAt: DateTime.now(),
      racks: oldOp.racks,
      batchIndex: oldOp.batchIndex,
    ));
    _recalculateStatsForCustomer(oldOp.customerId);
    if (custId != oldOp.customerId) _recalculateStatsForCustomer(custId);
    notifyListeners();
  }

  void updateOperationRacks(String opId, List<String> racks, int batchIndex) {
    final idx = _operations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    _operations[idx] = _operations[idx].copyWith(racks: racks, batchIndex: batchIndex);
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

  void deleteCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final customer = _customers.removeAt(idx);
    _deletedCustomers.add(customer);
    for (int i = _operations.length - 1; i >= 0; i--) {
      if (_operations[i].customerId == customerId) {
        final op = _operations.removeAt(i);
        _previousStatuses[op.id] = op.status;
        _deletedOperations.add(op.copyWith(status: OperationStatus.deleted, deletedAt: DateTime.now()));
      }
    }
    notifyListeners();
  }

  void toggleVip(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _customers[idx] = _customers[idx].copyWith(isVip: !_customers[idx].isVip);
    notifyListeners();
  }

  int _compareAlphabetical(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;

    final aFirst = a.trim().runes.first;
    final bFirst = b.trim().runes.first;

    final aIsArabic = _isArabicLetter(aFirst);
    final bIsArabic = _isArabicLetter(bFirst);
    final aIsLatin = _isLatinLetter(aFirst);
    final bIsLatin = _isLatinLetter(bFirst);

    if (aIsArabic && !bIsArabic) return -1;
    if (!aIsArabic && bIsArabic) return 1;

    if (aIsLatin && !bIsLatin) return -1;
    if (!aIsLatin && bIsLatin) return 1;

    return a.compareTo(b);
  }

  bool _isArabicLetter(int code) {
    return (code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF);
  }

  bool _isLatinLetter(int code) {
    return (code >= 0x0041 && code <= 0x005A) || (code >= 0x0061 && code <= 0x007A);
  }

  int _compareCustomers(MockCustomer a, MockCustomer b) {
    if (_sortMethod == SortMethod.alphabetical) {
      return _compareAlphabetical(a.primaryName, b.primaryName);
    } else {
      final aCount = getVisibleOpsCount(a.id);
      final bCount = getVisibleOpsCount(b.id);
      return bCount.compareTo(aCount);
    }
  }

  List<MockCustomer> getSortingCustomers() {
    final visible = _customers.where((c) => _hasVisibleOps(c.id)).toList();

    visible.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final aHasShelf = a.shelfNumbers.isNotEmpty;
      final bHasShelf = b.shelfNumbers.isNotEmpty;
      if (aHasShelf && bHasShelf) {
        return a.shelfNumbers.first.compareTo(b.shelfNumbers.first);
      }
      if (aHasShelf && !bHasShelf) return -1;
      if (!aHasShelf && bHasShelf) return 1;

      return _compareCustomers(a, b);
    });

    return visible;
  }

  int getVisibleOpsCount(String customerId) {
    return _operations.where((o) =>
        o.customerId == customerId &&
        (o.status == OperationStatus.unconfirmed ||
            o.status == OperationStatus.confirmed)).length;
  }

  MockCustomer? getCustomerAtShelf(int batchId, int shelfNumber) {
    for (final c in _customers) {
      if (c.assignedBatch == batchId && c.shelfNumbers.contains(shelfNumber)) {
        return c;
      }
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
        _customers[i] = _moveToEmptyShelf(c);
      }
    }

    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return displaced;

    final c = _customers[idx];
    final newShelves = [...c.shelfNumbers];
    if (!newShelves.contains(shelfNumber)) newShelves.add(shelfNumber);
    newShelves.sort();

    _customers[idx] = c.copyWith(shelfNumbers: newShelves, assignedBatch: batchId);

    notifyListeners();
    return displaced;
  }

  void removeShelf(String customerId, int shelfNumber) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final c = _customers[idx];
    final newShelves = c.shelfNumbers.where((s) => s != shelfNumber).toList();
    _customers[idx] = c.copyWith(
      shelfNumbers: newShelves,
      clearAssignedBatch: newShelves.isEmpty,
    );
    notifyListeners();
  }

  MockCustomer _moveToEmptyShelf(MockCustomer c) {
    final batchId = c.assignedBatch ?? 0;
    final shelfCount = _batches.firstWhere(
      (b) => b.id == batchId,
      orElse: () => _batches.first,
    ).shelvesCount;

    final occupied = getOccupiedShelves(batchId);
    for (int s = 1; s <= shelfCount; s++) {
      if (!occupied.containsKey(s)) {
        return c.copyWith(shelfNumbers: [s], assignedBatch: batchId);
      }
    }

    for (final b in _batches) {
      if (b.id == batchId) continue;
      final occ = getOccupiedShelves(b.id);
      for (int s = 1; s <= b.shelvesCount; s++) {
        if (!occ.containsKey(s)) {
          return c.copyWith(shelfNumbers: [s], assignedBatch: b.id);
        }
      }
    }

    if (_batches.length < _maxBatches) {
      final newBatch = addBatchInternal();
      return c.copyWith(shelfNumbers: [1], assignedBatch: newBatch.id);
    }

    return c.copyWith(shelfNumbers: const [], clearAssignedBatch: true);
  }

  void pinCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _customers[idx] = _customers[idx].copyWith(isPinned: true);
    notifyListeners();
  }

  void unpinCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _customers[idx] = _customers[idx].copyWith(isPinned: false);
    notifyListeners();
  }

  void autoAssignUnassigned() {
    final unassigned = _customers
        .where((c) =>
            c.shelfNumbers.isEmpty &&
            !c.isPinned &&
            _hasVisibleOps(c.id))
        .toList();

    if (unassigned.isEmpty) return;

    unassigned.sort(_compareCustomers);

    for (final c in unassigned) {
      _assignToFirstEmpty(c.id);
    }

    notifyListeners();
  }

  void fillGaps() {
    for (int i = 0; i < _customers.length; i++) {
      final c = _customers[i];
      if (c.isPinned) continue;
      if (c.shelfNumbers.isEmpty) continue;
      if (c.assignedBatch == null) continue;

      final currentShelf = c.shelfNumbers.first;
      final occupied = getOccupiedShelves(c.assignedBatch!);
      for (int s = 1; s < currentShelf; s++) {
        if (!occupied.containsKey(s)) {
          _customers[i] = c.copyWith(
            shelfNumbers: [s],
            assignedBatch: c.assignedBatch,
          );
          break;
        }
      }
    }

    final unassigned = _customers
        .where((c) => c.shelfNumbers.isEmpty && !c.isPinned && _hasVisibleOps(c.id))
        .toList();
    unassigned.sort(_compareCustomers);

    for (final c in unassigned) {
      _assignToFirstEmpty(c.id);
    }

    notifyListeners();
  }

  void reorderFullNonPinned() {
    for (int i = 0; i < _customers.length; i++) {
      final c = _customers[i];
      if (!c.isPinned) {
        _customers[i] = c.copyWith(shelfNumbers: const [], clearAssignedBatch: true);
      }
    }

    final unassigned = _customers
        .where((c) => c.shelfNumbers.isEmpty && _hasVisibleOps(c.id))
        .toList();
    unassigned.sort(_compareCustomers);

    for (final c in unassigned) {
      _assignToFirstEmpty(c.id);
    }

    notifyListeners();
  }

  void reorderFullAll() {
    for (int i = 0; i < _customers.length; i++) {
      _customers[i] = _customers[i].copyWith(
        shelfNumbers: const [],
        clearAssignedBatch: true,
        isPinned: false,
      );
    }

    final unassigned = _customers.where((c) => _hasVisibleOps(c.id)).toList();
    unassigned.sort(_compareCustomers);

    for (final c in unassigned) {
      _assignToFirstEmpty(c.id);
    }

    notifyListeners();
  }

  void _assignToFirstEmpty(String customerId) {
    for (final batch in _batches) {
      final occupied = getOccupiedShelves(batch.id);
      for (int s = 1; s <= batch.shelvesCount; s++) {
        if (!occupied.containsKey(s)) {
          final idx = _customers.indexWhere((c) => c.id == customerId);
          if (idx == -1) return;
          _customers[idx] = _customers[idx].copyWith(
            shelfNumbers: [s],
            assignedBatch: batch.id,
          );
          return;
        }
      }
    }
  }

  bool _hasVisibleOps(String customerId) {
    return _operations.any((o) =>
        o.customerId == customerId &&
        (o.status == OperationStatus.unconfirmed ||
            o.status == OperationStatus.confirmed));
  }

  void resetDistribution() {
    for (int i = 0; i < _customers.length; i++) {
      _customers[i] = _customers[i].copyWith(
        shelfNumbers: const [],
        clearAssignedBatch: true,
        isPinned: false,
      );
    }
    notifyListeners();
  }

  void setShelvesPerBatch(int count) {
    if (count < 1) return;
    _shelvesPerBatch = count;
    notifyListeners();
  }

  void setSortMethod(SortMethod method) {
    _sortMethod = method;
    notifyListeners();
  }

  BatchModel addBatchInternal() {
    final newId = _batches.isEmpty ? 0 : _batches.last.id + 1;
    final batch = BatchModel(
      id: newId,
      name: 'الوجبة ${newId + 1}',
      shelvesCount: _shelvesPerBatch,
      createdAt: DateTime.now(),
    );
    _batches.add(batch);
    return batch;
  }

  BatchModel addBatch({String? name}) {
    final batch = addBatchInternal();
    if (name != null) {
      final idx = _batches.indexWhere((b) => b.id == batch.id);
      if (idx != -1) {
        _batches[idx] = _batches[idx].copyWith(name: name);
      }
    }
    notifyListeners();
    return batch;
  }

  void assignBatch(String customerId, int batchId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _customers[idx] = _customers[idx].copyWith(assignedBatch: batchId);
    notifyListeners();
  }

  void _recalculateStatsForCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final ops = _operations.where((o) => o.customerId == customerId).toList();
    final totalOps = ops.length;
    final totalAmount = ops.fold<int>(0, (sum, o) => sum + o.amount);
    final pending = ops
        .where((o) => o.status == OperationStatus.unconfirmed || o.status == OperationStatus.confirmed)
        .toList();
    _customers[idx] = _customers[idx].copyWith(
      totalOps: totalOps,
      totalAmount: totalAmount,
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

  List<MockCustomer> searchCustomers(String query, {bool onlyVip = false}) {
    final q = normalizeArabic(query);
    return _customers.where((c) {
      if (onlyVip && !c.isVip) return false;
      if (q.isEmpty) return true;
      final name = normalizeArabic(c.primaryName);
      final aliases = c.aliases.map((a) => normalizeArabic(a)).join(' ');
      final phone = c.primaryPhone ?? '';
      return name.contains(q) || aliases.contains(q) || phone.contains(query.trim());
    }).toList();
  }

  String generateCustomerId() {
    _idCounter++;
    return 'c$_idCounter';
  }

  String getStoreName() => _storeName;

  void setStoreName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > 50) return;
    _storeName = trimmed;
    notifyListeners();
  }

  String getWhatsAppTemplate() => _whatsappTemplate;

  void setWhatsAppTemplate(String template) {
    _whatsappTemplate = template;
    notifyListeners();
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
        _operations.add(op.copyWith(status: previous, deletedAt: null));
      }
    }
    _recalculateStatsForCustomer(customerId);
    notifyListeners();
    return true;
  }

  bool restoreOperation(String opId) {
    final idx = _deletedOperations.indexWhere((o) => o.id == opId);
    if (idx == -1) return false;
    final op = _deletedOperations[idx];
    if (getCustomerById(op.customerId) == null) return false;
    _deletedOperations.removeAt(idx);
    final previous = _previousStatuses.remove(op.id) ?? OperationStatus.unconfirmed;
    _operations.add(op.copyWith(status: previous, deletedAt: null));
    _recalculateStatsForCustomer(op.customerId);
    notifyListeners();
    return true;
  }

  void permanentlyDeleteCustomer(String customerId) {
    final idx = _deletedCustomers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    _deletedCustomers.removeAt(idx);
    for (int i = _deletedOperations.length - 1; i >= 0; i--) {
      if (_deletedOperations[i].customerId == customerId) {
        final op = _deletedOperations.removeAt(i);
        _previousStatuses.remove(op.id);
      }
    }
    notifyListeners();
  }

  void permanentlyDeleteOperation(String opId) {
    final idx = _deletedOperations.indexWhere((o) => o.id == opId);
    if (idx == -1) return;
    final op = _deletedOperations.removeAt(idx);
    _previousStatuses.remove(op.id);
    notifyListeners();
  }

  Future<bool> replaceAllData({
    required List<MockCustomer> customers,
    required List<Operation> operations,
    required List<MockCustomer> deletedCustomers,
    required List<Operation> deletedOperations,
    required String storeName,
    required String whatsappTemplate,
  }) async {
    try {
      _customers.clear();
      _customers.addAll(customers);
      _operations.clear();
      _operations.addAll(operations);
      _deletedCustomers.clear();
      _deletedCustomers.addAll(deletedCustomers);
      _deletedOperations.clear();
      _deletedOperations.addAll(deletedOperations);
      _previousStatuses.clear();
      if (storeName.isNotEmpty) _storeName = storeName;
      if (whatsappTemplate.isNotEmpty) _whatsappTemplate = whatsappTemplate;
      for (final o in [..._operations, ..._deletedOperations]) {
        final n = int.tryParse(o.id.replaceFirst('op', ''));
        if (n != null && n > _idCounter) _idCounter = n;
        final s = int.tryParse(o.serial.replaceFirst('TA1-', ''));
        if (s != null && s > _serialCounter) _serialCounter = s;
      }
      for (final c in [..._customers, ..._deletedCustomers]) {
        final n = int.tryParse(c.id.replaceFirst('c', ''));
        if (n != null && n > _idCounter) _idCounter = n;
      }
      for (final c in _customers) {
        _recalculateStatsForCustomer(c.id);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}