import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/record_screen.dart';
import 'screens/report_screen.dart';
import 'screens/analysis_pipeline_screen.dart';
import 'screens/history_screen.dart';

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
      routes: {
        '/':        (context) => const HomeScreen(),
        '/record':  (context) => const RecordScreen(),
        '/pipeline':(context) => const AnalysisPipelineScreen(),
        '/report':  (context) => const ReportScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
