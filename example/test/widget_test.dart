import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_share_pro_example/main.dart';

void main() {
  testWidgets('Verify Buttons Exist', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the buttons are present
    expect(find.text('Share to Instagram Stories'), findsOneWidget);
    expect(find.text('Share to Facebook Stories'), findsOneWidget);
    expect(find.text('Share to WhatsApp Status'), findsOneWidget);
  });
}
