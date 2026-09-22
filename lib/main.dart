import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/analysis_pipeline_screen.dart';

void main() {
  runApp(const NeuroVoiceApp());
}

class NeuroVoiceApp extends StatelessWidget {
  const NeuroVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroVoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/pipeline') {
          return MaterialPageRoute(
            builder: (context) => const AnalysisPipelineScreen(),
            settings: settings,
          );
        }
        if (settings.name == '/record') {
          return MaterialPageRoute(
            builder: (context) => const MainShell(initialTab: 1),
            settings: settings,
          );
        }
        if (settings.name == '/report') {
          return MaterialPageRoute(
            builder: (context) => MainShell(
              initialTab: 2,
              initialReport: settings.arguments,
            ),
            settings: settings,
          );
        }
        if (settings.name == '/history') {
          return MaterialPageRoute(
            builder: (context) => const MainShell(initialTab: 3),
            settings: settings,
          );
        }
        // Default '/'
        return MaterialPageRoute(
          builder: (context) => const MainShell(initialTab: 0),
          settings: settings,
        );
      },
    );
  }
}
