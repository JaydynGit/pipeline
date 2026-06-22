import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'ui/screens/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PipelineApp(),
    ),
  );
}

class PipelineApp extends StatelessWidget {
  const PipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipeline A/B Tester',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LandingScreen(),
    );
  }
}
