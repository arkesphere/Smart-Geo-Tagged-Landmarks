import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'activity_screen.dart';
import 'add_screen.dart';
import 'landmarks_screen.dart';
import 'map_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up results the background worker wrote while we were away.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppState>().loadFromCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: IndexedStack(
        index: state.tab,
        children: const [
          MapScreen(),
          LandmarksScreen(),
          ActivityScreen(),
          AddScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state.tab,
        type: BottomNavigationBarType.fixed,
        onTap: state.setTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Landmarks'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add/View'),
        ],
      ),
    );
  }
}
