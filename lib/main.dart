import 'package:flutter/material.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UpAppState.instance.initialize();
  runApp(const UpEventosApp());
}

class UpEventosApp extends StatefulWidget {
  const UpEventosApp({super.key});
  @override
  State<UpEventosApp> createState() => _UpEventosAppState();
}

class _UpEventosAppState extends State<UpEventosApp> {
  final appState = UpAppState.instance;
  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }
  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }
  void _refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UP Eventos',
      debugShowCheckedModeBanner: false,
      theme: buildUpTheme(dark: false),
      darkTheme: buildUpTheme(dark: true),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UpAppState.instance,
      builder: (context, _) => UpAppState.instance.currentUser == null
          ? const LandingScreen()
          : const MainShell(),
    );
  }
}
