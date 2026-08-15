import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'background_sync.dart';
import 'ui/app_shell.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundSync.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..start(),
      child: MaterialApp(
        title: 'Smart Landmarks',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: const AppShell(),
      ),
    );
  }
}
