import 'package:flutter_test/flutter_test.dart';

import 'package:car_track/main.dart';

void main() {
  testWidgets('CarTrack app boots to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const CarTrackApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('CARTRACK'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
