import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/loan_session_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoanSessionState(),
      child: const ScanGoApp(),
    ),
  );
}

class ScanGoApp extends StatelessWidget {
  const ScanGoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan-Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
          background: Color(0xFF0F0F11),
          surface: Color(0xFF16161A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16161A),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF16161A),
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF16161A),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
