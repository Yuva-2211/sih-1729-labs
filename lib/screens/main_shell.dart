import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'report_screen.dart';
import 'history_screen.dart';

/// InheritedWidget providing tab switching functionality to any descendant screen.
class MainShellScope extends InheritedWidget {
  final int currentIndex;
  final void Function(int index, {dynamic extraData}) switchToTab;

  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.switchToTab,
    required super.child,
  });

  static MainShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class MainShell extends StatefulWidget {
  final int initialTab;
  final dynamic initialReport;

  const MainShell({
    super.key,
    this.initialTab = 0,
    this.initialReport,
  });

  @override
  State<MainShell> createState() => MainShellState();

  /// Utility to switch tabs from anywhere
  static void switchTab(BuildContext context, int index, {dynamic extraData}) {
    final scope = MainShellScope.of(context);
    if (scope != null) {
      scope.switchToTab(index, extraData: extraData);
    } else {
      // Fallback if opened standalone
      if (index == 0) Navigator.pushNamed(context, '/');
      if (index == 1) Navigator.pushNamed(context, '/record');
      if (index == 2) Navigator.pushNamed(context, '/report', arguments: extraData);
      if (index == 3) Navigator.pushNamed(context, '/history');
    }
  }
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;
  dynamic _latestReport;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _latestReport = widget.initialReport;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _currentIndex = widget.initialTab;
    }
    if (widget.initialReport != null && widget.initialReport != oldWidget.initialReport) {
      _latestReport = widget.initialReport;
      _currentIndex = 2;
    }
  }

  void switchToTab(int index, {dynamic extraData}) {
    setState(() {
      _currentIndex = index;
      if (extraData != null) {
        _latestReport = extraData;
      }
    });
  }

  void setLatestReport(dynamic report) {
    setState(() {
      _latestReport = report;
      _currentIndex = 2; // Auto-switch to Report tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      currentIndex: _currentIndex,
      switchToTab: switchToTab,
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                onStartScreening: () => switchToTab(1),
                onViewHistory: () => switchToTab(3),
              ),
              RecordScreen(
                onScreeningDone: (result) => switchToTab(2, extraData: result),
              ),
              ReportScreen(
                activeResult: _latestReport,
                onRecordAgain: () => switchToTab(1),
                onViewHistory: () => switchToTab(3),
              ),
              HistoryScreen(
                onSelectReport: (report) => switchToTab(2, extraData: report),
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => switchToTab(index),
          ),
        ),
      ),
    );
  }
}
