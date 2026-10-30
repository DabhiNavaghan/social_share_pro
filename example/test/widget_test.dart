import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_pro_example/main.dart';

void main() {
  testWidgets('shows every share section', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('Story with gradient'), findsOneWidget);
    expect(find.text('Story with background image'), findsOneWidget);
    expect(find.text('Direct message'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Save to gallery'), findsOneWidget);
  });
}
