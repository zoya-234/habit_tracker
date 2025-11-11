import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/add_habit_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();

    return MaterialApp(
      title: 'HabiTrack',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // ☀️ LIGHT THEME
      theme: baseLight.copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade600),
        textTheme: GoogleFonts.interTextTheme(baseLight.textTheme).apply(
          bodyColor: Colors.grey[900],
          displayColor: Colors.grey[900],
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.green.shade900),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.green.shade900,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade600,
        ),
      ),

      // 🌙 DARK (MIDNIGHT) THEME
      darkTheme: baseDark.copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B132B), // deep navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1C2541),
          secondary: Color(0xFF5BC0BE), // teal accent
          surface: Color(0xFF1B1B2F),
        ),
        textTheme: GoogleFonts.interTextTheme(baseDark.textTheme).apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white70,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.tealAccent),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.tealAccent,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF5BC0BE),
        ),
      ),

      // ROUTES
      initialRoute: '/',
      routes: {
        '/': (_) => HomeScreen(onToggleTheme: _toggleTheme),
        '/add': (_) => AddHabitScreen(),
      },
    );
  }
}
