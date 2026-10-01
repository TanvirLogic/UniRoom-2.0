import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniroom_mobile/providers/auth_provider.dart';
import 'package:uniroom_mobile/screens/register_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RegisterScreen renders role selector and cascading fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify key titles and labels
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Create Account')), findsOneWidget);
    expect(find.text('Join UniRoom-Live'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('CR (Class Rep)'), findsOneWidget);
    expect(find.text('Faculty'), findsOneWidget);

    // Verify form labels
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Student ID Number'), findsOneWidget);
    expect(find.text('Batch'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify submit button
    expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);

    // Test switching to Faculty role hides Student ID / Batch / Section and shows Faculty Initials
    await tester.tap(find.text('Faculty'));
    await tester.pumpAndSettle();

    expect(find.text('Faculty Code / Initials'), findsOneWidget);
    expect(find.text('Student ID Number'), findsNothing);
    expect(find.text('Batch'), findsNothing);
    expect(find.text('Section'), findsNothing);
  });
}
