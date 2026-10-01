import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniroom_mobile/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UniRoomMobileApp smoke test', (WidgetTester tester) async {
    // Build app widget
    await tester.pumpWidget(const UniRoomMobileApp());
    expect(find.byType(UniRoomMobileApp), findsOneWidget);

    // Advance time past the splash delay
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
  });
}
