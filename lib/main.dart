import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'utils/constants.dart';
import 'services/data_service.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DataService.instance.initialize();
  SettingsService.instance.initialize();
  runApp(const TajerAmazonApp());
}

class TajerAmazonApp extends StatefulWidget {
  const TajerAmazonApp({Key? key}) : super(key: key);

  @override
  State<TajerAmazonApp> createState() => _TajerAmazonAppState();
}

class _TajerAmazonAppState extends State<TajerAmazonApp> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
    // تطبيق الإعداد الأولي بعد أول frame (بعد تحميل القيم من الملف)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyWakelock();
    });
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _applyWakelock();
  }

  Future<void> _applyWakelock() async {
    try {
      final keepOn = SettingsService.instance.keepScreenOn;
      if (keepOn) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // تجاهل الأخطاء (مثلاً على منصات لا تدعم Wakelock)
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تاجر أمازون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kScaffoldBg,
        primaryColor: kPrimary,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}