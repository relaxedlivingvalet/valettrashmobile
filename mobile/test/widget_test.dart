import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valet/features/auth/screens/simple_auth_screen.dart';

void main() {
  testWidgets('SimpleAuthScreen shows sign in heading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SimpleAuthScreen()),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Sign In'), findsWidgets);
  });
}
