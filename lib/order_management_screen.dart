import 'package:flutter/material.dart';

const Color kScaffoldBg = Color(0xFF0E1621);
const Color kSurfaceColor = Color(0xFF17212B);
const Color kPrimary = Color(0xFF2AABEE);
const Color kPrimaryDark = Color(0xFF1565C0);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF7F91A4);

const Color kOrange = Color(0xFFF0883E);
const Color kGreen = Color(0xFF3FB950);
const Color kGray = Color(0xFF8B949E);
const Color kMutedOrange = Color(0xFFC26A2D);
const Color kMutedGreen = Color(0xFF348A4A);

class MockOrder {
  final String id;
  final String customerName;
  final int opsCount;
  final int totalAmount;
  final String date;

  MockOrder({
    required this.id,
    required this.customerName,
    required this.opsCount,
    required this.totalAmount,
    this.date = '2026-11-10',
  });
}

final List<MockOrder> _unconfirmedOrders = [
  MockOrder(id: '1', customerName: 'أحمد علي', opsCount: 6, totalAmount: 75000),
  MockOrder(id: '2', customerName: 'حميدة سالم', opsCount: 2, totalAmount: 30000),
  MockOrder(id: '3', customerName: 'محمد كريم', opsCount: 1, totalAmount: 15000),
];

final List<MockOrder> _confirmedOrders = [
  MockOrder(id: '4', customerName: 'زينب حسن', opsCount: 10, totalAmount: 120000),
  MockOrder(id: '5', customerName: 'علي جاسم', opsCount: 3, totalAmount: 22000),
];

final List<MockOrder> _deliveredOrders = [
  MockOrder(id: '6', customerName: 'فاطمة عبد', opsCount: 5, totalAmount: 60000, date: '2026-11-09'),
  MockOrder(id: '7', customerName: 'حسين كاظم', opsCount: 8, totalAmount: 95000, date: '2026-11-09'),
];

class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({Key? key, required this.index, required this.child}) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockOrder> _getFilteredData(List<MockOrder> data) {
    if (_searchQuery.isEmpty) return data;
    return data.where((o) => o.customerName.contains(_searchQuery)).toList();
  }

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
    final unconfirmed = _getFilteredData(_unconfirmedOrders);
    final confirmed = _getFilteredData(_confirmedOrders);
    final delivered = _getFilteredData(_deliveredOrders);

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
          title: const Text('إدارة الطلبات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    _buildTabButton('غير مؤكدة', 0, kOrange),
                    _buildTabButton('مؤكدة', 1, kGreen),
                    _buildTabButton('تم التوصيل', 2, kGray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: _neumorphicDecoration(radius: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('العملاء', '${_getFilteredData(_currentTab == 0 ? _unconfirmedOrders : _currentTab == 1 ? _confirmedOrders : _deliveredOrders).length}'),
                    Container(width: 1, height: 20, color: Colors.white12),
                    _buildStatItem('العمليات', '${_getFilteredData(_currentTab == 0 ? _unconfirmedOrders : _currentTab == 1 ? _confirmedOrders : _deliveredOrders).fold(0, (sum, item) => sum + item.opsCount)}'),
                    Container(width: 1, height: 20, color: Colors.white12),
                    _buildStatItem('المبلغ', '${_formatAmount(_getFilteredData(_currentTab == 0 ? _unconfirmedOrders : _currentTab == 1 ? _confirmedOrders : _deliveredOrders).fold(0, (sum, item) => sum + item.totalAmount))}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                decoration: _neumorphicDecoration(),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الهاتف...',
                    hintStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: kTextSecondary, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_currentTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    label: const Text('مسح جماعي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            if (_currentTab == 0) const SizedBox(height: 10),
            Expanded(
              child: _currentTab == 0
                  ? _buildOrderList(unconfirmed, isConfirmed: false, isDelivered: false)
                  : _currentTab == 1
                      ? _buildOrderList(confirmed, isConfirmed: true, isDelivered: false)
                      : _buildOrderList(delivered, isConfirmed: true, isDelivered: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, Color activeColor) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentTab != index) {
            setState(() {
              _currentTab = index;
              _searchController.clear();
              _searchQuery = '';
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? activeColor : kTextSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildOrderList(List<MockOrder> orders, {required bool isConfirmed, required bool isDelivered}) {
    if (orders.isEmpty) {
      return Center(
        key: ValueKey('empty-$isConfirmed-$isDelivered'),
        child: const Text('لا توجد طلبات', style: TextStyle(color: kTextSecondary, fontSize: 14)),
      );
    }

    return ListView.separated(
      key: ValueKey('list-$isConfirmed-$isDelivered'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        Color mutedColor = isDelivered ? kTextSecondary : (isConfirmed ? kMutedGreen : kMutedOrange);
        Color stripeColor = isDelivered ? Colors.transparent : mutedColor;

        return AnimatedListItem(
          index: index,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Container(
                decoration: _neumorphicDecoration().copyWith(
                  border: Border(
                    right: BorderSide(color: stripeColor, width: isDelivered ? 0 : 6),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isDelivered)
                          Text(order.date, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.opsCount} عمليات — ${_formatAmount(order.totalAmount)} د.ع',
                      style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (isConfirmed && !isDelivered) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: kPrimary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('وصل', style: TextStyle(color: kPrimary, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('تم التوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}