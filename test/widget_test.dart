import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elder_shield/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ElderShieldApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      find.byType(ProviderScope),
      findsOneWidget,
      reason: 'App root is mounted',
    );
  });
}
