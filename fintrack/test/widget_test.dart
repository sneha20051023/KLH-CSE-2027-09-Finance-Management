import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/main.dart';

void main() {
  testWidgets('FintrackApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FintrackApp());
  });
}
