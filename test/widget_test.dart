import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:car_track/data/app_store.dart';
import 'package:car_track/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Tests have no network; fall back to bundled fonts instead of hanging.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CarTrack loads home shell', (tester) async {
    final store = AppStore();
    await store.load();
    await tester.pumpWidget(CarTrackApp(store: store));
    // The car button pulses forever, so pumpAndSettle would never return.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CARTRACK'), findsOneWidget);
  });
}
