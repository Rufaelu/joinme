import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/app_shell.dart';
import 'package:joinme/src/Screens/auth_screen.dart';
import 'package:joinme/src/Screens/onboarding_screen.dart';
import 'package:joinme/src/Screens/create_event_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JoinMeApp());
}

class JoinMeApp extends StatefulWidget {
  const JoinMeApp({super.key});

  @override
  State<JoinMeApp> createState() => _JoinMeAppState();
}

class _JoinMeAppState extends State<JoinMeApp> {
  bool _initialized = false;
  bool _isDark = false;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('joinme_dark') ?? false;
      _hasSeenOnboarding = prefs.getBool('joinme_onboarding') ?? false;
      _initialized = true;
    });
  }

  Future<void> _setTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joinme_dark', value);
    setState(() => _isDark = value);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joinme_onboarding', true);
    setState(() => _hasSeenOnboarding = true);
  }

  ThemeData get _lightTheme {
    return ThemeData.light().copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF59E0B),
        brightness: Brightness.light,
        primary: const Color(0xFFF59E0B),
        secondary: const Color(0xFF3B82F6),
        surface: const Color(0xFFFFFFFF),
        background: const Color(0xFFF8FAFC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
      textTheme: ThemeData.light().textTheme.apply(bodyColor: const Color(0xFF0F172A), displayColor: const Color(0xFF0F172A)),
    );
  }

  ThemeData get _darkTheme {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF59E0B),
        brightness: Brightness.dark,
        primary: const Color(0xFFF59E0B),
        secondary: const Color(0xFF60A5FA),
        surface: const Color(0xFF1E293B),
        background: const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.white)),
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: const Color(0xFFF8FAFC), displayColor: const Color(0xFFF8FAFC)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/home': (context) => AppShell(onToggleTheme: () => _setTheme(!_isDark), isDark: _isDark),
        '/create': (context) => const CreateEventScreen(),
      },
      home: _hasSeenOnboarding
          ? Builder(
              builder: (context) => AuthScreen(
                onAuthenticated: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
            )
          : OnboardingScreen(onCompleted: _completeOnboarding),
    );
  }
}
