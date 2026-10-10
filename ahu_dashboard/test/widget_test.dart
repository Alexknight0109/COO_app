// This is a basic Flutter widget test for the AHU Dashboard

import 'package:flutter_test/flutter_test.dart';

import 'package:ahu_dashboard/main.dart';
import 'package:ahu_dashboard/providers/app_provider.dart';
import 'package:ahu_dashboard/providers/or_lights_provider.dart';
import 'package:ahu_dashboard/providers/or_session_provider.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    await tester.pumpWidget(AhuDashboardApp(
      appProvider: AppProvider(),
      orSession: OrSessionProvider(),
      orLights: OrLightsProvider(),
    ));

    expect(find.text('AHU Control'), findsOneWidget);
    expect(find.text('Hospital User'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });
}
