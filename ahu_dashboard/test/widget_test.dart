// This is a basic Flutter widget test for the AHU Dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ahu_dashboard/main.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AhuDashboardApp());

    // Verify that the login screen is displayed
    expect(find.text('AHU Control System'), findsOneWidget);
    expect(find.text('Hospital User'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });
}
