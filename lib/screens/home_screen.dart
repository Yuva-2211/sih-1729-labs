import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../widgets/v2_model_selector.dart';
import 'model_evolution_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onStartScreening;
  final VoidCallback? onViewHistory;

  const HomeScreen({
    super.key,
    this.onStartScreening,
    this.onViewHistory,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkingHealth = true;
  bool _backendOnline = false;
  ModelsStatus? _modelsStatus;
  ReportRecord? _latestRecord;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    _loadLatestRecord();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_backendOnline) {
        _checkBackendHealth();
      }
    });
  }

  Future<void> _loadLatestRecord() async {
    try {
      final reports = await DatabaseService().getAllReports();
      if (mounted && reports.isNotEmpty) {
        setState(() => _latestRecord = reports.first);
      }
    } catch (_) {}
  }

  Future<void> _checkBackendHealth() async {
    if (!mounted) return;
    setState(() => _checkingHealth = true);
    final status = await NeuralVoiceApi().getModelsStatus();
    if (mounted) {
      setState(() {
        _checkingHealth = false;
        _modelsStatus = status;
        _backendOnline = status != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: AppColors.surface.withValues(alpha: 0.8),
              elevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'NeuroVoice',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: V2ModelSelectorPill(
                    currentModelId: NeuralVoiceApi.activeModelVariant,
                    onSelected: (newId) {
                      setState(() {
                        NeuralVoiceApi.activeModelVariant = newId;
                        V2ModelRegistry.activeModelId = newId;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Tooltip(
                      message: _checkingHealth
                          ? 'Checking model service...'
                          : _backendOnline
                              ? 'Inference Engine Ready'
                              : 'Engine Offline (Tap to retry)',
                      child: InkWell(
                        onTap: _checkingHealth ? null : _checkBackendHealth,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (_backendOnline ? Colors.green : Colors.amber)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _checkingHealth
                                      ? Colors.amber
                                      : _backendOnline
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _backendOnline ? 'v2 Ready' : 'Connecting',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _backendOnline
                                      ? Colors.green.shade800
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkBackendHealth();
          await _loadLatestRecord();
        },
        color: AppColors.primaryContainer,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Clean Hero Action Card ──────────────────────────────
              _buildHeroCard(theme),
              const SizedBox(height: 24),

              // ── 2. Recent Screening Summary ────────────────────────────
              _buildRecentScreeningCard(theme),
              const SizedBox(height: 24),

              // ── 3. How It Works (3 Steps) ──────────────────────────────
              _buildHowItWorks(theme),
              const SizedBox(height: 24),

              // ── 4. Evaluator Specs & Benchmark (Collapsed) ─────────────
              _buildEvaluatorSpecsCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            const Color(0xFF3B39A0),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Non-Invasive Voice Screening',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Parkinson's Early Voice Screening",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyze vocal micro-tremors, pitch instability, and dysphonia biomarkers with on-device machine learning in seconds.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onStartScreening != null) {
                  widget.onStartScreening!();
                } else {
                  Navigator.pushNamed(context, '/record');
                }
              },
              icon: const Icon(Icons.mic_rounded, color: AppColors.primaryContainer, size: 22),
              label: const Text(
                'Start Voice Screening',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScreeningCard(ThemeData theme) {
    if (_latestRecord == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Screenings Recorded',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete your first voice test to monitor vocal health indicators.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final record = _latestRecord!;
    final isHigh = record.riskLevel == 'high';
    final isMod = record.riskLevel == 'moderate';
    final badgeColor = isHigh
        ? const Color(0xFFEF4444)
        : isMod
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return InkWell(
      onTap: () {
        if (widget.onViewHistory != null) {
          widget.onViewHistory!();
        } else {
          Navigator.pushNamed(context, '/history');
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Latest Screening',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${record.riskLevel.toUpperCase()} RISK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participant: ${record.patientName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Probability: ${(record.probability * 100).toStringAsFixed(1)}% • ${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Screening Works',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            theme,
            stepNumber: '1',
            icon: Icons.mic_none_rounded,
            title: 'Sustained Vowel Recording',
            desc: 'Hold the sustained vowel /aaah/ steadily for 5 to 10 seconds into your phone.',
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildStepRow(
            theme,
            stepNumber: '2',
            icon: Icons.graphic_eq_rounded,
            title: 'Acoustic Tremor Extraction',
            desc: 'On-device algorithms measure micro-tremors, F0 fundamental pitch, jitter, and shimmer.',
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildStepRow(
            theme,
            stepNumber: '3',
            icon: Icons.verified_user_outlined,
            title: 'Clinical Risk Classification',
            desc: 'Trained neural models evaluate patterns and generate a clinical probability report.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    ThemeData theme, {
    required String stepNumber,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: AppColors.primaryContainer),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluatorSpecsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Architecture & Evaluator Specs',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'SIH26139 • v2 Quantized Engine & Quantum VQC',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trained on 1,134 clinical audio samples with F0 Praat tremor extraction. Evaluated across 5-fold cross validation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showV2DetailsModal(context),
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('Benchmark Matrix', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModelEvolutionDetailScreen(
                          initialTopic: 'cv_accuracy',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Model Details', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showV2DetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.biotech_rounded,
                          color: AppColors.primaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'v1 vs v2 Benchmark Report',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'SIH26139 • MDVR-KCL & UCI Dataset Evaluation',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Benchmark Highlights
                  _buildBenchmarkHighlights(),
                  const SizedBox(height: 20),

                  // Comprehensive Comparison Table
                  _buildBenchmarkTable(Theme.of(context)),
                  const SizedBox(height: 24),

                  // Feature set upgrade note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: AppColors.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Key Acoustic Innovation',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v2 integrates Praat-grade F0 acoustic feature extraction (pitch tremor tracking, jitter, shimmer, HNR) aligned directly with clinical literature on neurodegenerative dysphonia.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBenchmarkHighlights() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'v2 CV Accuracy',
            val: '91.2%',
            sub: '+4.4% vs v1 (86.8%)',
            color: Colors.green,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Dataset Scale',
            val: '1,134',
            sub: 'vs 195 samples in v1',
            color: Colors.blue,
            icon: Icons.groups_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String val,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTable(ThemeData theme) {
    const rows = [
      ['Dataset Size', '195 samples', '1,134 samples (5.8×)'],
      ['Validation Method', 'Holdout (80/20)', '5-Fold Stratified CV'],
      ['CV Accuracy', '86.8%', '91.2% (±1.4%)'],
      ['ROC-AUC', '0.912', '0.957'],
      ['Serving Architecture', 'FP32 Only', 'FP32 • INT8 • Quantum VQC'],
      ['Model Footprint', '1.2 MB', '5.32 KB (INT8)'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('v1 (Legacy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('v2 (Active)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryContainer)),
                ),
              ],
            ),
          ),
          ...rows.map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(r[0], style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(r[1], style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(r[2], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
