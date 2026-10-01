import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniroom_mobile/providers/auth_provider.dart';
import 'package:uniroom_mobile/screens/reset_password_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ResetPasswordScreen renders 6-digit PIN boxes and password fields', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.setPendingEmail('student@uttara.edu.bd');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify header and target email
    expect(find.text('Set New Password'), findsOneWidget);
    expect(find.text('Reset for student@uttara.edu.bd'), findsOneWidget);
    expect(find.text('6-Digit Recovery PIN'), findsOneWidget);

    // Verify animated boxes are rendered (6 boxes in the row)
    expect(find.byType(AnimatedContainer), findsNWidgets(6));

    // Verify new password & confirm fields
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Update Password'), findsOneWidget);
  });
}
