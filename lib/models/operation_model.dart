enum OperationStatus {
  unconfirmed,
  confirmed,
  delivered,
  deleted,
}

class Operation {
  final String id;
  final String serial;
  final String customerId;
  final String customerName;
  final int amount;
  final bool isGift;
  final OperationStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<String> racks;
  final int batchIndex;
  final DateTime? deletedAt;

  const Operation({
    required this.id,
    required this.serial,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.isGift = false,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.racks = const [],
    this.batchIndex = 0,
    this.deletedAt,
  });

  Operation copyWith({
    String? id,
    String? serial,
    String? customerId,
    String? customerName,
    int? amount,
    bool? isGift,
    OperationStatus? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    List<String>? racks,
    int? batchIndex,
    DateTime? deletedAt,
  }) {
    return Operation(
      id: id ?? this.id,
      serial: serial ?? this.serial,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      isGift: isGift ?? this.isGift,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      racks: racks ?? this.racks,
      batchIndex: batchIndex ?? this.batchIndex,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}