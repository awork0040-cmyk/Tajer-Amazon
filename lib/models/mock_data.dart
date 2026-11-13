import 'customer_model.dart';

final List<MockCustomer> globalMockCustomers = [
  MockCustomer(id: '1', primaryName: 'أحمد علي', aliases: ['أبو علي'], primaryPhone: '07801234567', totalOps: 15, totalAmount: 250000, pendingOps: 6, pendingAmount: 75000, isVip: true),
  MockCustomer(id: '2', primaryName: 'حميدة سالم', totalOps: 2, totalAmount: 30000, pendingOps: 2, pendingAmount: 30000),
  MockCustomer(id: '3', primaryName: 'محمد كريم', aliases: ['محمد'], primaryPhone: '07709876543', totalOps: 8, totalAmount: 120000, pendingOps: 1, pendingAmount: 15000),
  MockCustomer(id: '4', primaryName: 'زينب حسن', aliases: ['أم حسين'], totalOps: 20, totalAmount: 400000, pendingOps: 10, pendingAmount: 120000, isVip: true),
  MockCustomer(id: '5', primaryName: 'علي جاسم', totalOps: 3, totalAmount: 22000, pendingOps: 3, pendingAmount: 22000),
  MockCustomer(id: '6', primaryName: 'فاطمة عبد', aliases: ['فطوم'], primaryPhone: '07811112222', totalOps: 0, totalAmount: 0, pendingOps: 0, pendingAmount: 0),
];