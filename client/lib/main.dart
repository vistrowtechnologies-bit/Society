import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const SocietyOSApp());
}

class SocietyOSApp extends StatelessWidget {
  const SocietyOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocietyOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
