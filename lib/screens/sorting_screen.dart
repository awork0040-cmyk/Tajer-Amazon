import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';
import '../widgets/animated_list_item.dart';
import 'sort_distribution_screen.dart';
import 'sorting_camera_screen.dart';

const Color kOrange = Color(0xFFF0883E);
const Color kDanger = Color(0xFFE53935);
const Color kPinGold = Color(0xFFFFC107);

class SortingScreen extends StatefulWidget {
  const SortingScreen({Key? key}) : super(key: key);
  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  int _currentBatch = 0;

  @override
  void initState() {
    super.initState();
    // توزيع تلقائي للعملاء الجدد (بدون رف) عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataService.instance.autoAssignUnassigned();
    });
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _batchLabel(int index) {
    const arabic = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة'];
    if (index >= 0 && index < arabic.length) return 'الوجبة ${arabic[index]}';
    return 'الوجبة ${index + 1}';
  }

  void _onMoreTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.space_dashboard_outlined, color: kPrimary),
                title: const Text('ملء الفراغات', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFillGapsDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort, color: kOrange),
                title: const Text('إعادة ترتيب كلي', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullReorderDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: kPrimary),
                title: const Text('إعدادات الفرز', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSettingsDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: kTextSecondary),
                title: const Text('إلغاء', style: TextStyle(color: kTextSecondary)),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFillGapsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'ملء الفراغات',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيتم إعادة ترتيب العملاء لملء الفراغات المتاحة، مع الحرص على إبقاء العملاء السابقين في أماكنهم قدر الإمكان.',
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'العملاء المثبتون (أصحاب الدبابيس) لا يتحركون من أماكنهم.',
              style: TextStyle(color: kPrimary, fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    DataService.instance.fillGaps();
    if (!mounted) return;
    _showSnack('تم ملء الفراغات', kPrimary);
  }

  Future<void> _showFullReorderDialog() async {
    bool reorderPinned = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return AlertDialog(
              backgroundColor: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'إعادة ترتيب كلي',
                style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سيتم إعادة ترتيب جميع العملاء في هذه الدفعة. يُرجى ملاحظة أن العملاء المثبتين (أصحاب الدبابيس) لن يتحركوا من أماكنهم إلا إذا قمت بتحديد الخيار أدناه.',
                      style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => setInner(() => reorderPinned = !reorderPinned),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: reorderPinned ? kDanger.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: reorderPinned ? kDanger.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: reorderPinned,
                              activeColor: kDanger,
                              onChanged: (v) => setInner(() => reorderPinned = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'إعادة ترتيب العملاء المثبتين أيضاً (أصحاب الدبابيس)',
                                style: TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reorderPinned
                          ? 'عند التحديد: جميع العملاء يُعاد ترتيبهم بما فيهم المثبتون.'
                          : 'عند عدم التحديد: العملاء المثبتون يبقون في أماكنهم، والباقي يُعاد ترتيبهم.',
                      style: TextStyle(
                        color: reorderPinned ? kDanger : kTextSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reorderPinned ? kDanger : kPrimaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    if (reorderPinned) {
      DataService.instance.reorderFullAll();
    } else {
      DataService.instance.reorderFullNonPinned();
    }
    if (!mounted) return;
    _showSnack('تمت إعادة الترتيب', kPrimary);
  }

  void _showSettingsDialog() {
    int tempShelves = DataService.instance.shelvesPerBatch;
    SortMethod tempMethod = DataService.instance.sortMethod;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return AlertDialog(
              backgroundColor: kSurfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'إعدادات الفرز',
                style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عدد الرفوف في الدفعة',
                      style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ملاحظة: يُطبَّق على الوجبات المستقبلية فقط، وليس الحالية.',
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kScaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (tempShelves > 1) setInner(() => tempShelves--);
                            },
                            icon: const Icon(Icons.remove, color: kPrimary, size: 20),
                          ),
                          Expanded(
                            child: Text(
                              '$tempShelves',
                              style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setInner(() => tempShelves++),
                            icon: const Icon(Icons.add, color: kPrimary, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'طريقة الترتيب التلقائي',
                      style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _buildRadio(ctx, tempMethod, SortMethod.alphabetical, 'أبجدي (عربي ← إنجليزي ← أرقام)', () {
                      setInner(() => tempMethod = SortMethod.alphabetical);
                    }),
                    _buildRadio(ctx, tempMethod, SortMethod.mostOperations, 'الأكثر بضاعة (عدد العمليات)', () {
                      setInner(() => tempMethod = SortMethod.mostOperations);
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmReset();
                        },
                        icon: const Icon(Icons.restart_alt, color: kDanger, size: 18),
                        label: const Text(
                          'إعادة ضبط توزيع الرفوف',
                          style: TextStyle(color: kDanger, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: kDanger.withOpacity(0.12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يمسح كل التوزيع اليدوي والتثبيت ويعيد الترتيب التلقائي.',
                      style: TextStyle(color: kTextSecondary, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          DataService.instance.setShelvesPerBatch(tempShelves);
                          DataService.instance.setSortMethod(tempMethod);
                          Navigator.pop(ctx);
                          _showSnack('تم حفظ الإعدادات', kPrimary);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark, elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadio(BuildContext ctx, SortMethod current, SortMethod value, String label, VoidCallback onTap) {
    final isSelected = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<SortMethod>(
              value: value,
              groupValue: current,
              activeColor: kPrimary,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? kPrimary : kTextPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'إعادة ضبط التوزيع',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'سيتم مسح كل التوزيع اليدوي والتثبيت، وإعادة الترتيب التلقائي.\n\nهل تريد المتابعة؟',
          style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إلغاء', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    DataService.instance.resetDistribution();
    if (!mounted) return;
    _showSnack('تم إعادة ضبط التوزيع', kDanger);
  }

  void _onLongPressCustomer(MockCustomer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(customer.primaryName,
                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.normal)),
              const SizedBox(height: 12),
              if (!customer.isPinned)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined, color: kPinGold),
                  title: const Text('تثبيت بدبوس 📌',
                    style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.normal)),
                  subtitle: const Text('لن يتحرك من مكانه (إلا إذا كُسر التثبيت يدوياً)',
                    style: TextStyle(color: kTextSecondary, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    DataService.instance.pinCustomer(customer.id);
                    _showSnack('تم تثبيت ${customer.primaryName}', kPinGold);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.push_pin, color: kPinGold),
                  title: const Text('إزالة الدبوس',
                    style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.normal)),
                  subtitle: const Text('سيصبح قابلاً للتحرك',
                    style: TextStyle(color: kTextSecondary, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    DataService.instance.unpinCustomer(customer.id);
                    _showSnack('تم إزالة التثبيت', kPrimary);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidingTabsBar(List<int> batchIds, int effectiveBatch) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final int count = batchIds.length;
        if (count == 0) return const SizedBox.shrink();
        final double tabWidth = w / count;
        final double indicatorWidth = tabWidth - 8;
        final int activeIdx = batchIds.indexOf(effectiveBatch);
        final double leftPos = (activeIdx >= 0 ? activeIdx * tabWidth : 0) + 4;

        return Container(
          height: 52,
          decoration: _neumorphicDecoration(radius: 12),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: leftPos, top: 4, bottom: 4, width: indicatorWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: batchIds.map((bId) {
                    final isActive = bId == effectiveBatch;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_currentBatch != bId) {
                            setState(() => _currentBatch = bId);
                          }
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              color: isActive ? kPrimary : kTextSecondary,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            child: Text(_batchLabel(bId), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final allSortingCustomers = DataService.instance.getSortingCustomers();

          final batchIds = <int>{};
          for (final b in DataService.instance.batches) {
            batchIds.add(b.id);
          }
          final batchIdsList = batchIds.toList()..sort();

          final int effectiveBatch = batchIdsList.isEmpty
              ? 0
              : (batchIdsList.contains(_currentBatch) ? _currentBatch : batchIdsList.first);

          final currentBatchCustomers = allSortingCustomers
              .where((c) => c.assignedBatch == effectiveBatch || c.assignedBatch == null)
              .toList();

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              )),
              title: const Text('وضع الفرز',
                style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _onMoreTap,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPrimary.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.more_vert, color: kPrimary, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: allSortingCustomers.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildSlidingTabsBar(batchIdsList, effectiveBatch),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: currentBatchCustomers.isEmpty
                              ? const Center(
                                  child: Text('لا يوجد عملاء في هذه الوجبة',
                                    style: TextStyle(color: kTextSecondary, fontSize: 14)))
                              : _buildCustomersList(currentBatchCustomers, effectiveBatch),
                        ),
                      ],
                    ),
            ),
            bottomNavigationBar: allSortingCustomers.isNotEmpty
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SortingCameraScreen())),
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                            label: const Text('بدء الفرز',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sort, size: 64, color: kTextSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('لا توجد عمليات للفرز',
              style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('أضف طلبات للعملاء أولاً\n(غير مؤكدة أو مؤكدة فقط تظهر هنا)',
              style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(List<MockCustomer> customers, int effectiveBatch) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = customers[index];
        final opsCount = DataService.instance.getVisibleOpsCount(c.id);
        final shelvesText = c.shelfNumbers.isEmpty ? 'بدون رف' : 'رف ${c.shelfNumbers.join('، ')}';

        return AnimatedListItem(
          key: ValueKey('sorting_b${effectiveBatch}_c${c.id}'),
          index: index,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SortDistributionScreen(customerId: c.id))),
              onLongPress: () => _onLongPressCustomer(c),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _neumorphicDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(c.primaryName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (c.isPinned) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.push_pin, color: kPinGold, size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$opsCount عمليات${c.isPinned ? " — موقع مقفول" : ""}',
                            style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(shelvesText,
                              style: TextStyle(
                                color: c.shelfNumbers.isEmpty ? kTextSecondary : kPrimary,
                                fontWeight: FontWeight.bold, fontSize: 13,
                              ),
                              textAlign: TextAlign.left, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kPrimary.withOpacity(0.3), width: 1),
                            ),
                            child: const Icon(Icons.edit, color: kPrimary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}