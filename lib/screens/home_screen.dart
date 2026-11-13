import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';
import 'quick_sale_screen.dart';
import 'order_management_screen.dart';
import 'sorting_screen.dart';
import 'settings_screen.dart';
import 'customer_list_screen.dart';
import 'qr_display_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DataService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: kScaffoldBg,
          appBar: AppBar(
            backgroundColor: kSurfaceColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              DataService.instance.getStoreName(),
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildListCard(
                  context: context,
                  title: 'البيع السريع',
                  subtitle: 'تسجيل عمليات البيع والطباعة الفورية',
                  icon: Icons.point_of_sale,
                  color: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickSaleScreen())),
                ),
                const SizedBox(height: 12),
                _buildListCard(
                  context: context,
                  title: 'إدارة الطلبات',
                  subtitle: 'مراجعة وتأكيد وتوصيل الطلبات',
                  icon: Icons.fact_check,
                  color: const Color(0xFFFF9800),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen())),
                ),
                const SizedBox(height: 12),
                _buildListCard(
                  context: context,
                  title: 'الفرز',
                  subtitle: 'توزيع الطلبات على الرفوف والوجبات',
                  icon: Icons.sort,
                  color: const Color(0xFF2196F3),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SortingScreen())),
                ),
                const SizedBox(height: 12),
                _buildListCard(
                  context: context,
                  title: 'عارض QR',
                  subtitle: 'مسح الملصقات لمعرفة تفاصيل العملية',
                  icon: Icons.qr_code_2,
                  color: const Color(0xFF673AB7),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrDisplayScreen())),
                ),
                const SizedBox(height: 12),
                _buildListCard(
                  context: context,
                  title: 'العملاء',
                  subtitle: 'عرض وإدارة قائمة العملاء',
                  icon: Icons.people,
                  color: const Color(0xFF00BCD4),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen())),
                ),
                const SizedBox(height: 12),
                _buildListCard(
                  context: context,
                  title: 'الإعدادات',
                  subtitle: 'الطابعة، الأصوات، والنسخ الاحتياطي',
                  icon: Icons.settings,
                  color: kTextSecondary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.all(16),
          decoration: _neumorphicDecoration(),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_back_ios_new,
                color: kTextSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}