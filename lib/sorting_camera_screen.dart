import 'package:flutter/material.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

class SortingCameraScreen extends StatelessWidget {
  const SortingCameraScreen({Key? key}) : super(key: key);

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
            width: 48,
            height: 48,
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
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
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
          title: const Text('بدء الفرز', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on, color: kPrimary, size: 28),
              onPressed: () {},
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Icon(Icons.camera_alt, color: Colors.white12, size: 120),
              ),
            ),
            
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: kSurfaceColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text('12 / 65', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('رف 3', style: TextStyle(color: kPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 10),
                    const Text('أحمد علي', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('الوجبة الأولى + 25,000 د.ع', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text('🟠 غير مؤكدة', style: TextStyle(color: Color(0xFFF0883E), fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}