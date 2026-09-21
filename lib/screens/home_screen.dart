import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../widgets/v2_model_selector.dart';
import 'model_evolution_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkingHealth = true;
  bool _backendOnline = false;
  ModelsStatus? _modelsStatus;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    // Auto-retry once after 2 seconds if initially offline
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_backendOnline) {
        _checkBackendHealth();
      }
    });
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
      extendBody: true,
      backgroundColor: AppColors.background.withValues(alpha: 0.8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ClipRRect(
          child: BackdropFilter(
            // Fix #12: real frosted-glass blur (was a no-op ColorFilter.mode(transparent))
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: AppColors.surface.withValues(alpha: 0.75),
              elevation: 0,
              centerTitle: false,
              shape: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              title: Text(
                'NeuroVoice',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              actions: [
                Center(
                  child: V2ModelSelectorPill(
                    // Fix #10: single source of truth — read from NeuralVoiceApi
                    currentModelId: NeuralVoiceApi.activeModelVariant,
                    onSelected: (newId) {
                      setState(() {
                        // Fix #10: write to both so widget layer stays in sync
                        NeuralVoiceApi.activeModelVariant = newId;
                        V2ModelRegistry.activeModelId = newId;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: Center(
                    child: Tooltip(
                      message: _checkingHealth
                          ? 'Connecting to backend...'
                          : _backendOnline
                              ? 'Backend Connected'
                              : 'Backend Not Connected (tap to re-test)',
                      child: InkWell(
                        onTap: _checkingHealth ? null : _checkBackendHealth,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _checkingHealth
                                  ? const Color(0xFFF59E0B) // Yellow / Amber while connecting
                                  : _backendOnline
                                      ? const Color(0xFF22C55E) // Green when connected
                                      : const Color(0xFFEF4444), // Red when not connected
                              boxShadow: [
                                BoxShadow(
                                  color: (_checkingHealth
                                          ? const Color(0xFFF59E0B)
                                          : _backendOnline
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1.5,
                                ),
                              ],
                            ),
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
      body: Stack(
        children: [
          // Background Gradient (replacing 3D iframe)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _checkBackendHealth,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 10 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Parkinson's voice screening",
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.displayLarge?.copyWith(
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 10 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Clinical-grade analysis powered by hybrid quantum machine learning.",
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  if (_modelsStatus != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.outlineVariant),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.memory, size: 14, color: AppColors.primaryContainer),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Active Models: Classical FP32 • INT8 ${!_modelsStatus!.hybridFp32 ? '' : '• Hybrid Quantum VQC'}',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                const SizedBox(height: 32),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    final adjustedValue = (value - 0.3).clamp(0.0, 0.7) / 0.7;
                                    return Opacity(
                                      opacity: adjustedValue,
                                      child: Transform.translate(
                                        offset: Offset(0, 10 * (1 - adjustedValue)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/record');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                                      side: BorderSide(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Start screening",
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: AppColors.primaryContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryContainer, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildV2UpgradeSection(context),
                          const SizedBox(height: 100), // Space for bottom nav bar
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/record');
          if (index == 2) Navigator.pushNamed(context, '/report');
          if (index == 3) Navigator.pushNamed(context, '/history');
        },
      ),
    );
  }

  Widget _buildV2UpgradeSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Evolution: v1 → v2',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'SIH26139 Quantum & Acoustic Upgrade',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'v2 Active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The inference engine now runs on the v2 architecture trained on an expanded cohort of 1,134 audio recordings, incorporating F0 pitch tremor tracking and mobile-optimized INT8 dynamic quantization.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),

          // 4 Minimal Topic Containers
          Row(
            children: [
              Expanded(
                child: _buildMinimalTopicCard(
                  context,
                  title: 'Dataset Scale',
                  icon: Icons.pie_chart_outline_rounded,
                  accentColor: Colors.blue,
                  topic: 'dataset_scale',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMinimalTopicCard(
                  context,
                  title: '5-Fold CV Accuracy',
                  icon: Icons.verified_outlined,
                  accentColor: Colors.green,
                  topic: 'cv_accuracy',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMinimalTopicCard(
                  context,
                  title: 'Acoustic Biomarkers',
                  icon: Icons.graphic_eq_rounded,
                  accentColor: Colors.purple,
                  topic: 'acoustic_biomarkers',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMinimalTopicCard(
                  context,
                  title: 'Mobile Edge Footprint',
                  icon: Icons.bolt_rounded,
                  accentColor: Colors.orange.shade800,
                  topic: 'mobile_edge',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View Full Benchmark Button
          InkWell(
            onTap: () => _showV2DetailsModal(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explore v1 vs v2 Benchmark Matrix',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTopicCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required String topic,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModelEvolutionDetailScreen(initialTopic: topic),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.outline.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Overview of Upgrades
                  _buildModalSectionHeader('1. Core Engineering Breakthroughs'),
                  const SizedBox(height: 10),
                  _buildUpgradePoint(
                    icon: Icons.balance_rounded,
                    title: 'Balanced Large-Scale Cohort (1,134 Audio Files)',
                    desc:
                        'v1 evaluated on pilot samples (~37 subjects). v2 trains on 1,134 real voice recordings (574 Healthy Controls / 560 Parkinson\'s) eliminating small-sample variance and false optimism.',
                  ),
                  _buildUpgradePoint(
                    icon: Icons.shield_rounded,
                    title: 'Rigorous 3-Way Split & Early Stopping',
                    desc:
                        '60% Train (680) · 20% Val (227) · 20% Test (227 held out). Early stopping with patience=15 restores best-epoch weights, preventing runaway overfitting and test-set data leakage.',
                  ),
                  _buildUpgradePoint(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Clinical F0 Pitch Biomarker via Random Forest',
                    desc:
                        'Extracted 40 acoustic candidates (Librosa + Praat). A 300-tree Random Forest selected the top-8 features, integrating F0 mean (fundamental frequency pitch tremor & monopitch dysarthria) alongside high-order MFCC variances.',
                  ),
                  _buildUpgradePoint(
                    icon: Icons.speed_rounded,
                    title: 'INT8 Quantization & TorchScript Mobile Ready',
                    desc:
                        'Classical INT8 dynamic quantization yields a tiny 5.32 KB footprint with 0.24 ms latency on CPU, matching full precision (0.9503 vs 0.9496 AUC). Pre-scripted for offline on-device mobile execution.',
                  ),

                  const SizedBox(height: 20),
                  // Section 2: Model Benchmark Table
                  _buildModalSectionHeader('2. 4-Model Comparative Benchmark Matrix'),
                  const SizedBox(height: 8),
                  Text(
                    'Evaluated directly on the held-out test set (227 samples, 16 kHz mono WAV):',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.surfaceContainerLowest,
                      ),
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('Model Variant', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Size (KB)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Latency (ms)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Accuracy', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('AUC', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Sensitivity', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Precision', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: [
                        _buildDataRow('Classical (FP32)', '4.13', '0.05', '90.8%', '0.9496', '84.8%', '96.0%', isBest: false),
                        _buildDataRow('Classical (INT8 Quantized)', '5.32', '0.24', '90.8%', '0.9503', '86.6%', '94.2%', isBest: true),
                        _buildDataRow('Hybrid Quantum (FP32)', '4.32', '19.37', '88.6%', '0.9192', '87.5%', '89.1%', isBest: false),
                        _buildDataRow('Hybrid Quantum (Quantized)', '5.63', '20.51', '87.7%', '0.9156', '85.7%', '88.9%', isBest: false),
                        _buildDataRow('Quantum Kernel SVM (qSVM)*', 'N/A', 'Subsample', '80.0%', '0.8681', '81.8%', '81.8%', isBest: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '*qSVM tested as an exploratory Track reference on high-dimensional quantum Hilbert mapping.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                          fontStyle: FontStyle.italic,
                          fontSize: 10.5,
                        ),
                  ),

                  const SizedBox(height: 20),
                  // Section 3: 5-Fold Stratified Cross-Validation
                  _buildModalSectionHeader('3. 5-Fold Stratified Cross-Validation'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        _buildCvRow('Classical NN', '92.5% ± 1.6%', '0.972 ± 0.005', '92.4% ± 2.1%', '92.5% ± 1.6%'),
                        const Divider(height: 16),
                        _buildCvRow('Hybrid Quantum (Shallow)', '90.5% ± 1.8%', '0.962 ± 0.014', '89.1% ± 3.5%', '92.1% ± 1.7%'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Section 4: Top 8 Quantum Features
                  _buildModalSectionHeader('4. Top-8 Biomarkers Selected for Quantum Embedding'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip('f0_mean', 'Pitch Tremor & Monopitch (NEW in v2)', isNew: true),
                      _buildFeatureChip('mfcc_std_1', 'MFCC-2 Spectral Tilt Variance'),
                      _buildFeatureChip('mfcc_std_3', 'MFCC-4 Formant Dispersion'),
                      _buildFeatureChip('mfcc_mean_1', 'MFCC-2 Mean (Vocal Cord Tilt)'),
                      _buildFeatureChip('mfcc_std_0', 'MFCC-1 Loudness Stability'),
                      _buildFeatureChip('mfcc_std_11', 'MFCC-12 Mucosal Perturbation'),
                      _buildFeatureChip('mfcc_std_10', 'MFCC-11 High Harmonic Irregularity'),
                      _buildFeatureChip('mfcc_std_2', 'MFCC-3 Formant Fluctuation (NEW in v2)', isNew: true),
                    ],
                  ),

                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done Exploring Benchmark'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppColors.primary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildUpgradePoint({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    String model,
    String size,
    String latency,
    String acc,
    String auc,
    String recall,
    String prec, {
    required bool isBest,
  }) {
    final style = TextStyle(
      fontSize: 11.5,
      fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
      color: isBest ? AppColors.primary : AppColors.onSurface,
    );
    return DataRow(
      color: isBest
          ? WidgetStateProperty.all(AppColors.primaryContainer.withValues(alpha: 0.08))
          : null,
      cells: [
        DataCell(Text(model, style: style)),
        DataCell(Text(size, style: style)),
        DataCell(Text(latency, style: style)),
        DataCell(Text(acc, style: style)),
        DataCell(Text(auc, style: style)),
        DataCell(Text(recall, style: style)),
        DataCell(Text(prec, style: style)),
      ],
    );
  }

  Widget _buildCvRow(String model, String acc, String auc, String prec, String recall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCvStat('Acc', acc),
            _buildCvStat('AUC', auc),
            _buildCvStat('Precision', prec),
            _buildCvStat('Recall', recall),
          ],
        ),
      ],
    );
  }

  Widget _buildCvStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.onSurface)),
      ],
    );
  }

  Widget _buildFeatureChip(String key, String label, {bool isNew = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isNew
            ? Colors.green.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNew
              ? Colors.green.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
          color: isNew ? Colors.green.shade900 : AppColors.onSurface,
        ),
      ),
    );
  }
}

