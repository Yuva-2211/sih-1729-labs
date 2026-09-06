import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({super.key});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  final Random random = Random();
  late List<double> waveformHeights;

  @override
  void initState() {
    super.initState();
    waveformHeights = List.generate(60, (index) => 10.0 + random.nextDouble() * 90.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'NeuroVoice',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History', style: theme.textTheme.headlineMedium),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        _buildHistoryItem(theme, 'Sep 5, 2026', 'Normal Analysis', Icons.check_circle, AppColors.primary),
                        const Divider(height: 32),
                        _buildHistoryItem(theme, 'Aug 22, 2026', 'Review Needed', Icons.warning, AppColors.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Waveform Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Session Audio', style: theme.textTheme.headlineMedium),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '00:14 / 00:42',
                                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Waveform Visualizer
                        Container(
                          height: 128,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(60, (index) {
                                  bool isActive = index < 20;
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      height: waveformHeights[index],
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.primaryContainer : AppColors.outlineVariant,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              Positioned(
                                left: MediaQuery.of(context).size.width * 0.3 - 48, // approximate 1/3 position
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(Icons.skip_previous, false),
                            const SizedBox(width: 16),
                            _buildControlButton(Icons.play_arrow, true),
                            const SizedBox(width: 16),
                            _buildControlButton(Icons.skip_next, false),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Analysis Detail',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Detail Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 600;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildBentoBox(
                              theme,
                              'Clinical Sentiment',
                              Column(
                                children: [
                                  _buildSentimentRow(theme, 'Vocal Stability', 'Stable', AppColors.primaryContainer, AppColors.primaryFixed),
                                  const SizedBox(height: 16),
                                  _buildSentimentRow(theme, 'Tremor Incidence', 'Detected', AppColors.error, AppColors.errorContainer),
                                  const SizedBox(height: 16),
                                  _buildSentimentRow(theme, 'Articulation Rate', 'Normal', AppColors.onSurfaceVariant, AppColors.surfaceContainer),
                                ],
                              ),
                            ),
                          ),
                          if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildBentoBox(
                              theme,
                              'Acoustic Metrics',
                              Column(
                                children: [
                                  _buildMetricRow(theme, 'Jitter (local)', '0.82%', 0.4),
                                  const SizedBox(height: 16),
                                  _buildMetricRow(theme, 'Shimmer (local)', '3.41%', 0.65),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Model Rationale
                  _buildBentoBox(
                    theme,
                    'Model Rationale',
                    Text(
                      'The neural analysis indicates minor irregularities in the high-frequency spectrum, consistent with early-stage tremor detection. The model assigns a 78% confidence interval to this finding, primarily driven by the observed shimmer variation during sustained vowel articulation. Background noise interference was minimal (< 2dB SNR).',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 80), // For bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 2,
        child: const Icon(Icons.share_rounded),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          if (index == 1) Navigator.pushReplacementNamed(context, '/record');
          if (index == 3) Navigator.pushReplacementNamed(context, '/result');
        },
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, String date, String status, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voice Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(date, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Text(status, style: theme.textTheme.bodyMedium?.copyWith(color: iconColor, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, bool isPrimary) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? AppColors.primaryContainer : AppColors.surfaceContainer,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
        ),
        onPressed: () {},
        iconSize: 24,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBentoBox(ThemeData theme, String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildSentimentRow(ThemeData theme, String label, String status, Color textColor, Color bgColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: bgColor),
          ),
          child: Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(ThemeData theme, String label, String value, double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            Text(value, style: theme.textTheme.titleLarge),
          ],
        ),
        Container(
          width: 64,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64 * progress,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}
