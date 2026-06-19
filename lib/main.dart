import 'package:curso_bqto_app/screens/calendario_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CursoBqtoApp());
}

class CursoBqtoApp extends StatelessWidget {
  const CursoBqtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curso Violonchelo BQTO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.dark(
          primary: Colors.amber.shade700,
          secondary: Colors.amber.shade200,
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      home: const CalendarioScreen(),
    );
  }
}
