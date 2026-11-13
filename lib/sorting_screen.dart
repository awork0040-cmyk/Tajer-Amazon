import 'package:flutter/material.dart';
import 'sort_distribution_screen.dart';
import 'sorting_camera_screen.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

class MockSortingCustomer {
  final String id;
  final String name;
  final int opsCount;
  final String racks;
  final bool isPinned;

  MockSortingCustomer({
    required this.id,
    required this.name,
    required this.opsCount,
    required this.racks,
    this.isPinned = false,
  });
}

final List<MockSortingCustomer> _mockSortingData = [
  MockSortingCustomer(id: '1', name: 'أحمد علي', opsCount: 6, racks: 'رف 1، 2', isPinned: true),
  MockSortingCustomer(id: '2', name: 'حميدة سالم', opsCount: 2, racks: 'رف 3'),
  MockSortingCustomer(id: '3', name: 'محمد كريم', opsCount: 1, racks: 'رف 4'),
  MockSortingCustomer(id: '4', name: 'زينب حسن', opsCount: 10, racks: 'رف 5، 6، 7'),
];

class SortingScreen extends StatefulWidget {
  const SortingScreen({Key? key}) : super(key: key);

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  int _currentBatch = 0;

  BoxDecoration _neumorphicDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? kSurfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
      ],
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
          title: const Text('وضع الفرز', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: kPrimary),
              color: kSurfaceColor,
              onSelected: (value) {},
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(value: 'reorder', child: Text('إعادة ترتيب 🔄', style: TextStyle(color: kTextPrimary))),
                  const PopupMenuItem(value: 'settings', child: Text('إعدادات الفرز ⚙️', style: TextStyle(color: kTextPrimary))),
                ];
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 52,
                decoration: _neumorphicDecoration(radius: 12),
                child: Row(
                  children: [
                    _buildTabButton('الوجبة الأولى', 0),
                    _buildTabButton('الوجبة الثانية', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _mockSortingData.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final customer = _mockSortingData[index];
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: _neumorphicDecoration(),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(customer.name, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (customer.isPinned) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.push_pin, color: kPrimary, size: 16),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${customer.opsCount} عمليات', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                                if (customer.isPinned)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text('📌 موقع مقفول', style: TextStyle(color: kPrimary, fontSize: 11)),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  customer.racks,
                                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => SortDistributionScreen()));
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: _neumorphicDecoration(radius: 8),
                                    child: const Icon(Icons.edit, color: kTextPrimary, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SortingCameraScreen()));
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                label: const Text('بدء الفرز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isActive = _currentBatch == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentBatch = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? kPrimary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isActive ? kPrimary : kTextSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ),
    );
  }
}