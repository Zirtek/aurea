import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AureaApp());
}

class AureaApp extends StatelessWidget {
  const AureaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurea',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97757),
          primary: const Color(0xFFD97757),
          secondary: const Color(0xFFD4A373),
          surface: const Color(0xFFFFFDF9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF7F2),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF2C2520),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF2ECE4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}