import 'package:flutter/material.dart';
import 'quick_sale_screen.dart';
import 'customer_selection_screen.dart';
import 'order_management_screen.dart';
import 'recent_operations_screen.dart';
import 'placeholder_screen.dart';

class AppRoutes {
  // أسماء الشاشات (ثابتة لا تتغير أبداً)
  static const String home = '/';
  static const String quickSale = '/quick_sale';
  static const String orders = '/orders';
  static const String sorting = '/sorting';
  static const String history = '/history';
  static const String customers = '/customers';
  static const String qrScanner = '/qr_scanner';
  static const String settings = '/settings';
  static const String recentOperations = '/recent_operations';
  static const String addCustomer = '/add_customer';

  // دالة التوجيه (Switchboard)
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case quickSale:
        return MaterialPageRoute(builder: (_) => const QuickSaleScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrderManagementScreen());
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerSelectionScreen());
      case recentOperations:
        return MaterialPageRoute(builder: (_) => const RecentOperationsScreen());
        
      // الشاشات المستقبلية (مؤقتاً PlaceholderScreen)
      case sorting:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'الفرز'));
      case history:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'السجل'));
      case qrScanner:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'عرض الملصق'));
      case settings:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'الإعدادات'));
      case addCustomer:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'إضافة عميل'));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('لا يوجد شاشة بهذا الاسم: ${routeSettings.name}')),
          ),
        );
    }
  }
}