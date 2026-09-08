import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:car_track/data/app_store.dart';
import 'package:car_track/main.dart';

void main() {
  testWidgets('CarTrack loads home shell', (tester) async {
    final store = AppStore();
    await store.load();
    await tester.pumpWidget(CarTrackApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('CARTRACK'), findsOneWidget);
  });
}
