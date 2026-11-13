import 'package:flutter_test/flutter_test.dart';
import 'package:tajer_amazon/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TajerAmazonApp());
  });
}