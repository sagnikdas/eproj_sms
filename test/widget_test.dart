import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elder_shield/app.dart';

void main() {
  testWidgets('App renders HomeScreen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ElderShieldApp()));
    expect(find.text('Elder Shield'), findsWidgets);
  });
}
