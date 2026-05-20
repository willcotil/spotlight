import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlight/app/home_screen.dart';
import 'package:spotlight/providers/theme_provider.dart';

class SpotlightApp extends StatelessWidget {
  const SpotlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<ThemeProvider>().darkMode;

    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor:
          darkMode ? const Color(0xFF09090B) : const Color(0xFFFAFAFA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF27272A),
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      textTheme: Typography.blackMountainView,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotlight',
      theme: base,
      home: const HomeScreen(),
    );
  }
}
