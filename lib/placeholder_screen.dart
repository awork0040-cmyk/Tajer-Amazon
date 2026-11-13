import 'package:flutter/material.dart';

const Color kScaffoldBg = Color(0xFF0D1117);
const Color kSurfaceColor = Color(0xFF161B22);
const Color kPrimary = Color(0xFF00ACC1);
const Color kTextPrimary = Color(0xFFC9D1D9);
const Color kTextSecondary = Color(0xFF8B949E);

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          backgroundColor: kSurfaceColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'شاشة $title قيد الإنشاء',
            style: const TextStyle(color: kTextSecondary, fontSize: 16),
          ),
        ),
      ),
    );
  }
}