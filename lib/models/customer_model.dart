class MockCustomer {
  final String id;
  final String primaryName;
  final List<String> aliases;
  final String? primaryPhone;
  final List<String> secondaryPhones;
  final String? address;
  final String? notes;
  final int totalOps;
  final int totalAmount;
  final int pendingOps;
  final int pendingAmount;
  final bool isVip;

  final List<int> shelfNumbers;
  final bool isPinned;
  final int? assignedBatch;
  final DateTime? lastUsedAt;

  const MockCustomer({
    required this.id,
    required this.primaryName,
    this.aliases = const [],
    this.primaryPhone,
    this.secondaryPhones = const [],
    this.address,
    this.notes,
    this.totalOps = 0,
    this.totalAmount = 0,
    this.pendingOps = 0,
    this.pendingAmount = 0,
    this.isVip = false,
    this.shelfNumbers = const [],
    this.isPinned = false,
    this.assignedBatch,
    this.lastUsedAt,
  });

  MockCustomer copyWith({
    String? id,
    String? primaryName,
    List<String>? aliases,
    String? primaryPhone,
    List<String>? secondaryPhones,
    String? address,
    String? notes,
    int? totalOps,
    int? totalAmount,
    int? pendingOps,
    int? pendingAmount,
    bool? isVip,
    List<int>? shelfNumbers,
    bool? isPinned,
    int? assignedBatch,
    DateTime? lastUsedAt,
    bool clearAssignedBatch = false,
    bool clearLastUsedAt = false,
  }) {
    return MockCustomer(
      id: id ?? this.id,
      primaryName: primaryName ?? this.primaryName,
      aliases: aliases ?? this.aliases,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhones: secondaryPhones ?? this.secondaryPhones,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalOps: totalOps ?? this.totalOps,
      totalAmount: totalAmount ?? this.totalAmount,
      pendingOps: pendingOps ?? this.pendingOps,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isVip: isVip ?? this.isVip,
      shelfNumbers: shelfNumbers ?? this.shelfNumbers,
      isPinned: isPinned ?? this.isPinned,
      assignedBatch: clearAssignedBatch ? null : (assignedBatch ?? this.assignedBatch),
      lastUsedAt: clearLastUsedAt ? null : (lastUsedAt ?? this.lastUsedAt),
    );
  }
}