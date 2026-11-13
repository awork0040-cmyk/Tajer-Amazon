import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isConnected = false;
  String? _lastPrinterName;
  bool _isSearching = false;
  List<String> _discoveredPrinters = [];

  double _density = 3.0;
  double _timeout = 10.0;
  int _printMethod = 0;

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleConnection() {
    setState(() {
      if (_isConnected) {
        _isConnected = false;
        _lastPrinterName = null;
      } else {
        _isConnected = true;
        _lastPrinterName = 'طابعة Xprinter';
      }
    });
    _showSnackBar(
      _isConnected ? 'تم الاتصال بالطابعة' : 'تم قطع الاتصال',
      _isConnected ? Colors.green : kTextSecondary,
    );
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _discoveredPrinters = [];
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _discoveredPrinters = ['طابعة Xprinter', 'طابعة Zebra ZD220', 'طابعة Canon LPB'];
      });
    });
  }

  void _testPrint() {
    if (!_isConnected) {
      _showSnackBar('الرجاء الاتصال بالطابعة أولاً', Colors.red);
      return;
    }
    _showSnackBar('جاري إرسال عملية اختبار...', kPrimaryDark);
  }

  void _forgetPrinter() {
    setState(() {
      _isConnected = false;
      _lastPrinterName = null;
      _discoveredPrinters = [];
    });
    _showSnackBar('تم نسيان الطابعة', Colors.red);
  }

  void _connectToPrinter(String name) {
    setState(() {
      _isConnected = true;
      _lastPrinterName = name;
      _discoveredPrinters = [];
    });
    _showSnackBar('تم الاتصال بـ $name', Colors.green);
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withOpacity(0.15) : kScaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive ? Colors.red.withOpacity(0.35) : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintMethodTab(String title, int index) {
    final isActive = _printMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _printMethod = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? kPrimary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? kPrimary : kTextSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
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
          title: const Text('إعدادات الطابعة', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ============ قسم الاتصال ============
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _neumorphicDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('حالة الاتصال', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleConnection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _isConnected ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isConnected ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isConnected ? Icons.print : Icons.print_disabled,
                                  color: _isConnected ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _isConnected ? 'متصل بـ ${_lastPrinterName ?? "الطابعة"}' : 'اتصال بالطابعة',
                                    style: TextStyle(
                                      color: _isConnected ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: _buildActionButton(icon: Icons.search, label: 'بحث', color: kPrimary, onTap: _startSearch)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(icon: Icons.print, label: 'اختبار', color: kPrimary, onTap: _testPrint)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(icon: Icons.delete_sweep, label: 'نسيان', color: Colors.red, isDestructive: true, onTap: _forgetPrinter)),
                        ],
                      ),

                      if (_isSearching) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator(color: kPrimary)),
                      ] else if (_discoveredPrinters.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 1, thickness: 0.5),
                        const SizedBox(height: 12),
                        ..._discoveredPrinters.map((printer) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: kScaffoldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: Text(printer, style: const TextStyle(color: kTextPrimary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                  TextButton(
                                    onPressed: () => _connectToPrinter(printer),
                                    child: const Text('اتصال', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // ============ قسم إعدادات الطباعة ============
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _neumorphicDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إعدادات الطباعة', style: TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('كثافة الطباعة', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                          Text('${_density.toInt()}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _density,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: kPrimary,
                        inactiveColor: kScaffoldBg,
                        onChanged: (v) => setState(() => _density = v),
                      ),
                      
                      const Divider(color: Colors.white12, height: 16, thickness: 0.5),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('مهلة الاتصال (ثانية)', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                          Text('${_timeout.toInt()}s', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _timeout,
                        min: 2,
                        max: 15,
                        divisions: 13,
                        activeColor: kPrimary,
                        inactiveColor: kScaffoldBg,
                        onChanged: (v) => setState(() => _timeout = v),
                      ),
                      
                      const Divider(color: Colors.white12, height: 16, thickness: 0.5),

                      const Text('طريقة الطباعة', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: kScaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildPrintMethodTab('مباشرة', 0),
                            _buildPrintMethodTab('معاينة', 1),
                          ],
                        ),
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
  }
}