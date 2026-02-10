import 'package:flutter_test/flutter_test.dart';

import 'package:hot_vault/app/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const HotVaultApp());

    expect(find.text('Hot Vault'), findsOneWidget);
    expect(find.text('Welcome to Hot Vault'), findsOneWidget);
  });
}
