import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_store.dart';
import 'data/notification_service.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final store = AppStore();
  await store.load();
  runApp(CarTrackApp(store: store));
}

class CarTrackApp extends StatelessWidget {
  const CarTrackApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'CarTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
