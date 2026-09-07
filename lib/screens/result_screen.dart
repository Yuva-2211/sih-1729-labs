import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _confidenceAnimation;

  PredictionResult? _result;

  // ---- Risk level color mapping ------------------------------------------
  static const Map<String, Color> _riskColors = {
    'low': Color(0xFF5F8F6B),       // green
    'moderate': Color(0xFFD4A017),  // amber
    'high': Color(0xFFB85450),      // red
  };

  static const Map<String, IconData> _riskIcons = {
    'low': Icons.check_circle_outline,
    'moderate': Icons.warning_amber_outlined,
    'high': Icons.error_outline,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _confidenceAnimation =
        Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get result passed from AnalysisPipelineScreen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PredictionResult && _result == null) {
      _result = args;
      _confidenceAnimation = Tween<double>(
        begin: 0.0,
        end: _result!.confidencePercent,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback if no result passed (shouldn't happen in normal flow)
    if (_result == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final r = _result!;
    final riskColor = _riskColors[r.riskLevel] ?? AppColors.primary;
    final riskIcon = _riskIcons[r.riskLevel] ?? Icons.info_outline;

    // Top 3 features by absolute value
    final sortedFeatures = r.selectedFeatures.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final topFeatures = sortedFeatures.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
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
        actions: [
          Center(
            child: Text(
              'Step 3 of 3',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.outlineVariant, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // ---- Risk icon + label --------------------------------
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) => Transform.scale(
                          scale: 0.95 + 0.05 * value,
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: Column(
                          children: [
                            Icon(riskIcon, color: riskColor, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              r.riskLabel,
                              style: theme.textTheme.displayLarge
                                  ?.copyWith(color: riskColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ---- Confidence / probability -------------------------
                      AnimatedBuilder(
                        animation: _confidenceAnimation,
                        builder: (context, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_confidenceAnimation.value.toStringAsFixed(1)}%',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' PD risk probability',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Latency chip
                      Chip(
                        label: Text(
                          '${r.inferenceLatencyMs.toStringAsFixed(0)} ms inference · ${r.modelUsed}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        backgroundColor: AppColors.surfaceContainerLowest,
                        side: BorderSide(color: AppColors.outlineVariant),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 24),

                      // ---- Info cards -------------------------------------
                      LayoutBuilder(builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 600;
                        return Flex(
                          direction:
                              isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildInfoCard(
                                theme,
                                Icons.memory,
                                'Model used',
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    r.modelUsed,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            color: AppColors.primaryContainer),
                                  ),
                                ),
                              ),
                            ),
                            if (isWide)
                              const SizedBox(width: 16)
                            else
                              const SizedBox(height: 16),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildInfoCard(
                                theme,
                                Icons.insights,
                                'Key influencing features',
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: topFeatures
                                      .asMap()
                                      .entries
                                      .map((e) => _buildListItem(
                                          theme,
                                          '${e.key + 1}',
                                          _humanFeatureName(e.value.key),
                                          e.key > 0))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 24),

                      // ---- LLM Recommendation ----------------------------
                      _buildRecommendationCard(theme, r),

                      const SizedBox(height: 48),

                      // ---- Actions ---------------------------------------
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/record',
                                (r) => false,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Record again'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/detail',
                                      arguments: r),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Full report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          if (index == 1) Navigator.pushReplacementNamed(context, '/record');
        },
      ),
    );
  }

  // ---- Widgets ------------------------------------------------------------

  Widget _buildRecommendationCard(ThemeData theme, PredictionResult r) {
    final riskColor = _riskColors[r.riskLevel] ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: riskColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendation',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(
            r.llmRecommendation.isNotEmpty
                ? r.llmRecommendation
                : r.recommendation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️  This is a screening tool, not a medical diagnosis. Always consult a qualified neurologist.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      ThemeData theme, IconData icon, String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.outline),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildListItem(
      ThemeData theme, String index, String text, bool hasTopBorder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: hasTopBorder
            ? Border(top: BorderSide(color: AppColors.surfaceVariant))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text('$index.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ------------------------------------------------------------

  String _humanFeatureName(String key) {
    const labels = {
      'mfcc_mean_0': 'MFCC-1 mean (vocal tract shape)',
      'mfcc_mean_1': 'MFCC-2 mean (spectral tilt)',
      'mfcc_std_0': 'MFCC-1 variability (voice stability)',
      'mfcc_std_1': 'MFCC-2 variability',
      'mfcc_std_3': 'MFCC-4 variability',
      'mfcc_std_4': 'MFCC-5 variability',
      'mfcc_std_6': 'MFCC-7 variability',
      'mfcc_std_10': 'MFCC-11 variability',
      'mfcc_std_11': 'MFCC-12 variability',
      'jitter_local': 'Jitter (pitch irregularity)',
      'shimmer_local': 'Shimmer (amplitude irregularity)',
      'hnr': 'Harmonics-to-Noise Ratio',
      'f0_mean': 'Mean pitch (F0)',
      'zcr': 'Zero-crossing rate',
      'spec_centroid': 'Spectral centroid',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }
}
