import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hot_vault/app/app.dart';
import 'package:hot_vault/core/di/service_locator.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await setupServiceLocator();
  });

  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Set a realistic phone screen size
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const HotVaultApp());

    // The app should render a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify app is using Material design
    expect(find.byType(Scaffold), findsWidgets);

    // Pump through the splash screen timer (3 seconds)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
