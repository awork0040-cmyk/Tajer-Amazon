class MockCustomer {
  final String id;
  final String primaryName;
  final String? alias;
  final String? phone;
  final String? notes;
  final int pendingOpsCount;
  final int pendingAmount;

  MockCustomer({
    required this.id,
    required this.primaryName,
    this.alias,
    this.phone,
    this.notes,
    this.pendingOpsCount = 0,
    this.pendingAmount = 0,
  });
}