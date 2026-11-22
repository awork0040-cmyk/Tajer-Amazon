import 'package:flutter/material.dart';
import '../utils/constants.dart';
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
  int? _selectedBatchId;
  final Set<int> _selectedShelves = {};

  @override
  void initState() {
    super.initState();
    final customer = DataService.instance.getCustomerById(widget.customerId);
    if (customer != null) {
      _selectedBatchId = customer.assignedBatch;
      _selectedShelves.addAll(customer.shelfNumbers);
    }
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

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  BatchModel? _getSelectedBatch() {
    if (_selectedBatchId == null) return null;
    for (final b in DataService.instance.batches) {
      if (b.id == _selectedBatchId) return b;
    }
    return null;
  }

  String _batchLabel(BatchModel batch) {
    if (batch.name.isNotEmpty) return batch.name;
    const arabic = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة'];
    if (batch.id >= 0 && batch.id < arabic.length) return 'الوجبة ${arabic[batch.id]}';
    return 'الوجبة ${batch.id + 1}';
  }

  Future<void> _openBatchesSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  const Text('الوجبات',
                      style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ...DataService.instance.batches.map((b) {
                          final isSelected = b.id == _selectedBatchId;
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? kPrimary : kTextSecondary,
                            ),
                            title: Text(
                              _batchLabel(b),
                              style: TextStyle(
                                color: isSelected ? kPrimary : kTextPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('${b.shelvesCount} رف',
                                style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                            onTap: () {
                              setState(() {
                                _selectedBatchId = b.id;
                                _selectedShelves.clear();
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                        const Divider(color: Colors.white10),
                        if (DataService.instance.batches.length >= DataService.instance.maxBatches)
                          const ListTile(
                            leading: Icon(Icons.block, color: kTextSecondary),
                            title: Text('وصلت للحد الأقصى (5 وجبات)',
                                style: TextStyle(color: kTextSecondary, fontSize: 13)),
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline, color: kPrimary),
                            title: const Text('دفعة جديدة',
                                style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                            onTap: () {
                              final newBatch = DataService.instance.addBatch();
                              if (newBatch == null) {
                                Navigator.pop(ctx);
                                _showSnack('وصلت للحد الأقصى (5 وجبات)', kDanger);
                                return;
                              }
                              setState(() {
                                _selectedBatchId = newBatch.id;
                                _selectedShelves.clear();
                              });
                              Navigator.pop(ctx);
                              _showSnack('تم إنشاء ${_batchLabel(newBatch)}', kPrimary);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openShelvesPicker() async {
    final batch = _getSelectedBatch();
    if (batch == null) {
      _showSnack('اختر وجبة أولاً', kDanger);
      return;
    }

    final myName = DataService.instance.getCustomerById(widget.customerId)?.primaryName ?? '';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            final occupied = DataService.instance.getOccupiedShelves(batch.id);
            return Container(
              decoration: const BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      Text('اختر الرفوف — ${_batchLabel(batch)}',
                          style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('أزرق = رفوفك، رمادي = فارغ، برتقالي = مشغول',
                          style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(batch.shelvesCount, (i) {
                              final shelfNo = i + 1;
                              final isMine = _selectedShelves.contains(shelfNo);
                              final owner = occupied[shelfNo];
                              final isOccupiedByOther = owner != null && owner != myName;
                              Color bg;
                              Color fg;
                              if (isMine) {
                                bg = kPrimary;
                                fg = Colors.white;
                              } else if (isOccupiedByOther) {
                                bg = kOrange.withOpacity(0.25);
                                fg = kOrange;
                              } else {
                                bg = Colors.white.withOpacity(0.05);
                                fg = kTextSecondary;
                              }
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  if (isMine) {
                                    setInner(() => _selectedShelves.remove(shelfNo));
                                    setState(() {});
                                  } else if (isOccupiedByOther) {
                                    final ok = await _confirmDisplace(owner);
                                    if (ok == true) {
                                      setInner(() => _selectedShelves.add(shelfNo));
                                      setState(() {});
                                    }
                                  } else {
                                    setInner(() => _selectedShelves.add(shelfNo));
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  width: 56, height: 48,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isMine ? kPrimary : Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$shelfNo',
                                      style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('تم',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDisplace(String ownerName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('رف مشغول',
            style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: Text('هذا الرف مشغول بـ ($ownerName). هل تريد إزاحته؟',
            style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
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
                    backgroundColor: kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('إزاحة',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final customer = DataService.instance.getCustomerById(widget.customerId);
    if (customer == null) return;

    if (_selectedBatchId == null) {
      if (_selectedShelves.isEmpty) {
        for (final s in List<int>.from(customer.shelfNumbers)) {
          DataService.instance.removeShelf(widget.customerId, s);
        }
        _showSnack('تم مسح التعيينات', kPrimary);
        Navigator.pop(context);
        return;
      }
      _showSnack('اختر وجبة أولاً', kDanger);
      return;
    }

    final oldShelves = List<int>.from(customer.shelfNumbers);
    for (final s in oldShelves) {
      if (!_selectedShelves.contains(s)) {
        DataService.instance.removeShelf(widget.customerId, s);
      }
    }

    final displaced = <String>[];
    for (final s in _selectedShelves) {
      final names = DataService.instance.assignShelf(widget.customerId, _selectedBatchId!, s);
      for (final n in names) {
        if (!displaced.contains(n)) displaced.add(n);
      }
    }

    if (displaced.isNotEmpty) {
      _showSnack('تم الحفظ — تمت إزاحة: ${displaced.join('، ')}', kOrange);
    } else {
      _showSnack('تم الحفظ', kPrimary);
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

          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0, centerTitle: true, toolbarHeight: 70, leadingWidth: 70,
              leading: Center(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1C2733),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              title: const Text('توزيع الرفوف',
                  style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            body: customer == null
                ? const Center(child: Text('العميل غير موجود', style: TextStyle(color: kTextSecondary)))
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard('اسم العميل', customer.primaryName),
                          const SizedBox(height: 10),
                          _buildInfoCard('عدد العمليات',
                              '${DataService.instance.getVisibleOpsCount(customer.id)} عمليات'),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الرفوف المختارة',
                                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
                              TextButton.icon(
                                onPressed: _selectedBatchId == null ? null : _openShelvesPicker,
                                icon: Icon(Icons.edit,
                                    color: _selectedBatchId == null ? kTextSecondary : kPrimary, size: 16),
                                label: Text('تعديل',
                                    style: TextStyle(
                                        color: _selectedBatchId == null ? kTextSecondary : kPrimary,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _selectedShelves.isEmpty
                              ? const Text('لم يتم اختيار رفوف بعد',
                                  style: TextStyle(color: kTextSecondary, fontSize: 13))
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (_selectedShelves.toList()..sort())
                                      .map((s) => _buildChip('رف $s'))
                                      .toList(),
                                ),
                          const SizedBox(height: 20),
                          const Text('الدفعة', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _getSelectedBatch() == null
                                  ? const Text('لم يتم اختيار وجبة',
                                      style: TextStyle(color: kTextSecondary, fontSize: 13))
                                  : _buildChip(_batchLabel(_getSelectedBatch()!)),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _openBatchesSheet,
                                icon: const Icon(Icons.add, color: kPrimary, size: 16),
                                label: const Text('اختيار/إضافة وجبة',
                                    style: TextStyle(color: kPrimary, fontSize: 13)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 55,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text('إلغاء',
                                        style: TextStyle(color: kTextSecondary, fontSize: 15)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _onSave,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    child: const Text('حفظ',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _neumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}