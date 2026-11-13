import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/customer_model.dart';
import '../services/data_service.dart';

const Color kOrange = Color(0xFFF0883E);
const Color kDanger = Color(0xFFE53935);

class SortDistributionScreen extends StatefulWidget {
  final String customerId;
  const SortDistributionScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<SortDistributionScreen> createState() => _SortDistributionScreenState();
}

class _SortDistributionScreenState extends State<SortDistributionScreen> {
  int? _selectedBatch;
  List<int> _selectedShelves = [];

  @override
  void initState() {
    super.initState();
    final c = DataService.instance.getCustomerById(widget.customerId);
    if (c != null) {
      _selectedBatch = c.assignedBatch ?? (DataService.instance.batches.isNotEmpty ? DataService.instance.batches.first.id : null);
      _selectedShelves = List.from(c.shelfNumbers);
    }
  }

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

  Future<void> _openShelvesSheet() async {
    if (_selectedBatch == null) {
      _showSnack('اختر وجبة أولاً', kOrange);
      return;
    }
    final batch = DataService.instance.batches.firstWhere(
      (b) => b.id == _selectedBatch,
      orElse: () => DataService.instance.batches.first,
    );

    final result = await showModalBottomSheet<List<int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ShelvesSheet(
        batchId: _selectedBatch!,
        batchName: _batchLabel(_selectedBatch!),
        shelvesCount: batch.shelvesCount,
        currentCustomerId: widget.customerId,
        initialSelection: _selectedShelves,
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedShelves = result);
    }
  }

  Future<void> _openBatchesSheet() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BatchesSheet(currentBatch: _selectedBatch),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedBatch = result;
        _selectedShelves = [];
      });
    }
  }

  Future<void> _onSave() async {
    if (_selectedBatch == null) {
      _showSnack('اختر وجبة أولاً', kOrange);
      return;
    }

    final customer = DataService.instance.getCustomerById(widget.customerId);
    if (customer == null) {
      _showSnack('العميل غير موجود', kDanger);
      return;
    }

    final displaced = <String>[];

    for (final oldShelf in customer.shelfNumbers) {
      if (!_selectedShelves.contains(oldShelf)) {
        DataService.instance.removeShelf(widget.customerId, oldShelf);
      }
    }

    for (final newShelf in _selectedShelves) {
      final names = DataService.instance.assignShelf(widget.customerId, _selectedBatch!, newShelf);
      displaced.addAll(names);
    }

    if (!mounted) return;

    if (displaced.isNotEmpty) {
      _showSnack('تم النقل. أُزيح: ${displaced.toSet().join('، ')}', kOrange);
    } else {
      _showSnack('تم حفظ التوزيع', kPrimary);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: DataService.instance,
        builder: (context, _) {
          final customer = DataService.instance.getCustomerById(widget.customerId);
          if (customer == null) {
            return Scaffold(
              backgroundColor: kScaffoldBg,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Center(child: _buildFloatingButton(
                  icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              ),
              body: const Center(child: Text('العميل غير موجود', style: TextStyle(color: kTextSecondary))),
            );
          }

          final opsCount = DataService.instance.getVisibleOpsCount(customer.id);

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(child: _buildFloatingButton(
                icon: Icons.arrow_back, onTap: () => Navigator.pop(context))),
              title: const Text('توزيع الطلبات',
                style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCustomerCard(customer, opsCount),
                  const SizedBox(height: 16),
                  _buildShelvesCard(),
                  const SizedBox(height: 16),
                  _buildBatchCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('إلغاء',
                            style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: kPrimaryDark.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: ElevatedButton(
                            onPressed: _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryDark, elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                              ),
                            ),
                            child: const Text('حفظ',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(MockCustomer customer, int opsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('العميل', style: TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(customer.primaryName,
            style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.25), width: 1),
            ),
            child: Text('$opsCount عمليات',
              style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildShelvesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('الرفوف المختارة',
                style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _openShelvesSheet,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('تغيير',
                  style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedShelves.isEmpty)
            const Text('لا توجد رفوف مختارة',
              style: TextStyle(color: kTextSecondary, fontSize: 13))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _selectedShelves.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimary.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('رف $s',
                        style: const TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() {
                          _selectedShelves = _selectedShelves.where((x) => x != s).toList();
                        }),
                        child: const Icon(Icons.close, color: kPrimary, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('الوجبة',
                style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _openBatchesSheet,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('تغيير',
                  style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedBatch == null)
            const Text('لم تُحدَّد وجبة',
              style: TextStyle(color: kTextSecondary, fontSize: 13))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimary.withOpacity(0.35), width: 1),
              ),
              child: Text(_batchLabel(_selectedBatch!),
                style: const TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ═══ Shelves Sheet ═══
class _ShelvesSheet extends StatefulWidget {
  final int batchId;
  final String batchName;
  final int shelvesCount;
  final String currentCustomerId;
  final List<int> initialSelection;

  const _ShelvesSheet({
    Key? key,
    required this.batchId,
    required this.batchName,
    required this.shelvesCount,
    required this.currentCustomerId,
    required this.initialSelection,
  }) : super(key: key);

  @override
  State<_ShelvesSheet> createState() => _ShelvesSheetState();
}

class _ShelvesSheetState extends State<_ShelvesSheet> {
  late List<int> _selection;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _jumpController = TextEditingController();

  static const int _columns = 5;
  static const double _tileSize = 60;
  static const double _gap = 8;

  @override
  void initState() {
    super.initState();
    _selection = List.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _toggleShelf(int shelf) {
    setState(() {
      if (_selection.contains(shelf)) {
        _selection.remove(shelf);
      } else {
        _selection.add(shelf);
      }
    });
  }

  void _jumpToShelf() {
    final n = int.tryParse(_jumpController.text.trim());
    if (n == null || n < 1 || n > widget.shelvesCount) return;
    final row = (n - 1) ~/ _columns;
    final offset = row * (_tileSize + _gap);
    _scrollController.animateTo(offset,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final occupied = DataService.instance.getOccupiedShelves(widget.batchId);

    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(widget.batchName,
                      style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${_selection.length} مختار',
                      style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: kScaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  ),
                  child: TextField(
                    controller: _jumpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _jumpToShelf(),
                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اذهب إلى رف...',
                      hintStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 18),
                      suffixIcon: IconButton(
                        onPressed: _jumpToShelf,
                        icon: const Icon(Icons.arrow_back, color: kPrimary, size: 18),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columns,
                      crossAxisSpacing: _gap,
                      mainAxisSpacing: _gap,
                      childAspectRatio: 1,
                    ),
                    itemCount: widget.shelvesCount,
                    itemBuilder: (context, index) {
                      final shelf = index + 1;
                      final isSelected = _selection.contains(shelf);
                      final occupiedBy = occupied[shelf];
                      final isOccupiedByOther = occupiedBy != null &&
                          DataService.instance.getCustomerAtShelf(widget.batchId, shelf)?.id != widget.currentCustomerId;

                      Color bgColor, textColor, borderColor;
                      if (isSelected) {
                        bgColor = kPrimary.withOpacity(0.25);
                        textColor = kPrimary;
                        borderColor = kPrimary;
                      } else if (isOccupiedByOther) {
                        bgColor = kOrange.withOpacity(0.15);
                        textColor = kOrange;
                        borderColor = kOrange.withOpacity(0.5);
                      } else {
                        bgColor = kScaffoldBg;
                        textColor = kTextPrimary;
                        borderColor = Colors.white.withOpacity(0.05);
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _toggleShelf(shelf),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: 1.2),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$shelf',
                                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                if (isOccupiedByOther)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(occupiedBy,
                                      style: const TextStyle(color: kOrange, fontSize: 8),
                                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_selection.any((s) {
                final occ = occupied[s];
                return occ != null && DataService.instance.getCustomerAtShelf(widget.batchId, s)?.id != widget.currentCustomerId;
              }))
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kOrange.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: kOrange, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('رف مشغول: سيُزاح صاحبه إلى آخر رف فارغ.',
                          style: TextStyle(color: kOrange, fontSize: 11, height: 1.4, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء',
                            style: TextStyle(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, _selection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryDark, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('حفظ الاختيار',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ Batches Sheet ═══
class _BatchesSheet extends StatelessWidget {
  final int? currentBatch;
  const _BatchesSheet({Key? key, this.currentBatch}) : super(key: key);

  String _batchLabel(int index) {
    const arabic = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة'];
    if (index >= 0 && index < arabic.length) return 'الوجبة ${arabic[index]}';
    return 'الوجبة ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final batches = DataService.instance.batches;
    final canAdd = batches.length < DataService.instance.maxBatches;

    return Container(
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('اختر الوجبة',
                style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ...batches.map((b) {
              final isActive = currentBatch == b.id;
              return ListTile(
                leading: Icon(
                  isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isActive ? kPrimary : kTextSecondary, size: 20,
                ),
                title: Text(_batchLabel(b.id),
                  style: TextStyle(
                    color: isActive ? kPrimary : kTextPrimary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  )),
                onTap: () => Navigator.pop(context, b.id),
              );
            }),
            const SizedBox(height: 8),
            ListTile(
              enabled: canAdd,
              leading: Icon(Icons.add_circle_outline,
                color: canAdd ? kPrimary : kTextSecondary.withOpacity(0.4), size: 20),
              title: Text('+ وجبة جديدة',
                style: TextStyle(
                  color: canAdd ? kPrimary : kTextSecondary.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                )),
              onTap: canAdd
                  ? () {
                      final newBatch = DataService.instance.addBatch();
                      Navigator.pop(context, newBatch.id);
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('وصلت للحد الأقصى (5 وجبات)'),
                        backgroundColor: kOrange,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}