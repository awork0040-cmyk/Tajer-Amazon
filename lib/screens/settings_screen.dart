import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'printer_settings_screen.dart';
import 'store_name_screen.dart';
import 'data_management_screen.dart';
import 'app_info_screen.dart';
import 'whatsapp_messages_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: const Color(0xFF1C2733),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48, height: 48,
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
          title: const Text('الإعدادات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildListCard(
                context: context,
                title: 'اسم المتجر',
                subtitle: 'تعديل اسم المتجر الذي يظهر في الملصقات',
                icon: Icons.store,
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreNameScreen())),
              ),
              const SizedBox(height: 12),
              _buildListCard(
                context: context,
                title: 'الطابعة وتصميم الملصق',
                subtitle: 'إعدادات الاتصال بالطابعة وتخصيص الملصق',
                icon: Icons.print,
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
              ),
              const SizedBox(height: 12),
              _buildListCard(
                context: context,
                title: 'رسائل WhatsApp',
                subtitle: 'تخصيص القالب النصي لرسائل العملاء',
                icon: Icons.message,
                color: const Color(0xFF25D366),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppMessagesScreen())),
              ),
              const SizedBox(height: 12),
              _buildListCard(
                context: context,
                title: 'إدارة البيانات',
                subtitle: 'النسخ الاحتياطي، الاستعادة، وسلة المحذوفات',
                icon: Icons.folder,
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen())),
              ),
              const SizedBox(height: 12),
              _buildListCard(
                context: context,
                title: 'معلومات التطبيق',
                subtitle: 'الإصدار، المطور، وأرقام التواصل',
                icon: Icons.info_outline,
                color: kTextSecondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoScreen())),
              ),
            ],
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
                    BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
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
                    Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new, color: kTextSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}