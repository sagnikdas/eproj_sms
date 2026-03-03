import 'package:flutter/material.dart';
import 'package:elder_shield/presentation/home/home_screen.dart';

class ElderShieldApp extends StatelessWidget {
  const ElderShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elder Shield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        // Larger default text for elderly-friendly readability
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          bodyLarge: TextStyle(fontSize: 18),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
