import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/settings_service.dart';

class SoundsVibrationScreen extends StatelessWidget {
  const SoundsVibrationScreen({Key? key}) : super(key: key);

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5)),
      ],
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: const Color(0xFF1C2733),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
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
          title: const Text(
            'الأصوات والاهتزاز',
            style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        body: ListenableBuilder(
          listenable: SettingsService.instance,
          builder: (context, _) {
            final s = SettingsService.instance;
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionCard(
                    title: 'صوت واهتزاز المسح',
                    icon: Icons.qr_code_scanner,
                    children: [
                      _buildSwitchRow(
                          'صوت المسح', s.scanSound, (v) => s.setScanSound(v)),
                      _buildSwitchRow('اهتزاز المسح', s.scanVibration,
                          (v) => s.setScanVibration(v)),
                      _buildSwitchRow('اهتزاز عند الخطأ', s.errorVibration,
                          (v) => s.setErrorVibration(v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'أصوات الأزرار',
                    icon: Icons.touch_app,
                    children: [
                      _buildSwitchRow('صوت عند الضغط على زر', s.buttonSound,
                          (v) => s.setButtonSound(v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'العرض',
                    icon: Icons.phone_android,
                    children: [
                      _buildSwitchRow('إبقاء الشاشة مضاءة', s.keepScreenOn,
                          (v) => s.setKeepScreenOn(v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'التحكم العام',
                    icon: Icons.tune,
                    children: [
                      _buildSliderRow('مستوى الصوت', Icons.volume_up,
                          s.volumeLevel, (v) => s.setVolumeLevel(v)),
                      const SizedBox(height: 8),
                      _buildSliderRow('قوة الاهتزاز', Icons.vibration,
                          s.vibrationLevel, (v) => s.setVibrationLevel(v)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        s.resetAll();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('تمت إعادة ضبط الإعدادات'),
                          backgroundColor: const Color(0xFF3FB950),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      icon: const Icon(Icons.restore,
                          color: Color(0xFFE53935), size: 20),
                      label: const Text(
                        'إعادة ضبط الكل',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: const Color(0xFFE53935).withOpacity(0.5),
                            width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.05), height: 1, thickness: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14))),
          Switch(value: value, activeColor: kPrimary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
      String label, IconData icon, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: kTextPrimary, fontSize: 14)),
            const Spacer(),
            Text('${(value * 100).round()}%',
                style: const TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          activeColor: kPrimary,
          inactiveColor: kPrimary.withOpacity(0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}