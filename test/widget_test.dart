// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shooting_online_multiplayer/src/app.dart';

void main() {
  testWidgets('shows multiplayer lobby', (WidgetTester tester) async {
    await tester.pumpWidget(const ShootingGameApp());

    await tester.pump();

    expect(find.text('MYTHIC\nSIEGE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Forge Room'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Forge Room'), findsOneWidget);
    expect(find.text('Join Warband'), findsOneWidget);
  });
}
