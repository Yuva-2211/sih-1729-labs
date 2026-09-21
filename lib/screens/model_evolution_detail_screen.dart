import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModelEvolutionDetailScreen extends StatefulWidget {
  final String initialTopic;

  const ModelEvolutionDetailScreen({
    super.key,
    required this.initialTopic,
  });

  @override
  State<ModelEvolutionDetailScreen> createState() => _ModelEvolutionDetailScreenState();
}

class _ModelEvolutionDetailScreenState extends State<ModelEvolutionDetailScreen> {
  late String _activeTopic;

  @override
  void initState() {
    super.initState();
    _activeTopic = widget.initialTopic;
  }

  String _topicTitle(String topic) {
    switch (topic) {
      case 'dataset_scale':
        return 'Dataset Scale';
      case 'cv_accuracy':
        return '5-Fold CV Accuracy';
      case 'acoustic_biomarkers':
        return 'Acoustic Biomarkers';
      case 'mobile_edge':
        return 'Mobile Edge Footprint';
      default:
        return 'Model Evolution';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to Home',
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Home',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _topicTitle(_activeTopic),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Topic Content
            _buildTopicContent(context, _activeTopic),

            const SizedBox(height: 32),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 24),

            // Navigation Chips to explore other topics
            Text(
              'Explore Other Evolution Pillars',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTopicChip('dataset_scale', 'Dataset Scale', Icons.pie_chart_outline_rounded),
                _buildTopicChip('cv_accuracy', '5-Fold CV Accuracy', Icons.verified_outlined),
                _buildTopicChip('acoustic_biomarkers', 'Acoustic Biomarkers', Icons.graphic_eq_rounded),
                _buildTopicChip('mobile_edge', 'Mobile Edge Footprint', Icons.bolt_rounded),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip(String topic, String title, IconData icon) {
    final isCurrent = _activeTopic == topic;
    return InkWell(
      onTap: () {
        if (!isCurrent) {
          setState(() {
            _activeTopic = topic;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isCurrent ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? AppColors.primaryContainer : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicContent(BuildContext context, String topic) {
    switch (topic) {
      case 'dataset_scale':
        return _buildDatasetScaleDetails(context);
      case 'cv_accuracy':
        return _buildCvAccuracyDetails(context);
      case 'acoustic_biomarkers':
        return _buildAcousticBiomarkersDetails(context);
      case 'mobile_edge':
        return _buildMobileEdgeDetails(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. DATASET SCALE DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildDatasetScaleDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Header
        _buildHeroBanner(
          theme: theme,
          badge: 'COHORT EXPANSION: 14x DATA GROWTH',
          title: 'Dataset Scale & Cohort Distribution',
          subtitle:
              'Transitioning from an unstable pilot sample to an extensive, clinically-balanced 1,134-recording cohort.',
          accentColor: Colors.blue,
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 24),

        // Comparison Table / Cards
        _buildSideBySideCard(
          v1Title: 'v1 Pilot (workbook.ipynb)',
          v1Points: [
            'Dataset: MDVR-KCL pilot dataset (Zenodo)',
            'Cohort size: Only 37 human subjects total',
            'Sample count: 81 WAV files (HC: 40, PD: 41)',
            'Train / Val / Test: 48 / 16 / 17 samples',
            'Flaw: With only 17 test samples, a single subject swinging results altered accuracy by ~15-20%. Extreme risk of statistical bias and false optimism.',
          ],
          v2Title: 'v2 Clinical Pipeline (v2-sih.ipynb)',
          v2Points: [
            'Dataset: Multi-center Voice_Dataset corpus',
            'Cohort size: Comprehensive large-scale cohort',
            'Sample count: 1,134 high-quality WAV audio files',
            'Balanced split: 574 Healthy Controls · 560 Parkinson\'s (50.6% / 49.4%)',
            'Train / Val / Test: 680 Train · 227 Val · 227 Test',
            'Benefit: 14x dataset expansion (+1,300% samples) guarantees statistical significance and real-world generalizability.',
          ],
          accentColor: Colors.blue,
        ),
        const SizedBox(height: 24),

        // Deep Dive Section
        _buildDeepDiveSection(
          theme: theme,
          title: 'Why This Scale Upgrade Was Imperative',
          paragraphs: [
            'In acoustic Parkinson\'s diagnosis, small cohorts (< 100 samples) suffer from severe acoustic variance. Background microphone noise, room acoustic reflections, and individual voice timbres easily confound machine learning classifiers.',
            'By scaling from 81 to 1,134 audio files, the v2 model learned invariant dysphonia features rather than memorizing individual vocal characteristics. Furthermore, the 50.6% / 49.4% class balance ensures the classifier avoids majority-class bias without artificial synthetic oversampling.',
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. 5-FOLD CV ACCURACY DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildCvAccuracyDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          theme: theme,
          badge: 'STATISTICAL VALIDATION & RECALL',
          title: '5-Fold Stratified Cross-Validation',
          subtitle:
              'Achieving 92.5% clinical recall and 0.972 AUC with early-stopping regularization.',
          accentColor: Colors.green,
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 24),

        _buildSideBySideCard(
          v1Title: 'v1 Pilot (workbook.ipynb)',
          v1Points: [
            'Classical 5-Fold Accuracy: 70.4% ± 2.7%',
            'Classical 5-Fold AUC: 0.827 ± 0.034',
            'Clinical Sensitivity / Recall: 55.0% ± 6.8% — CRITICAL DEFECT: missed 45% of genuine Parkinson\'s cases!',
            'Hybrid Quantum CV Accuracy: 70.4% ± 11.7% (massive ±11.7% volatility between folds)',
            'Test Set Accuracy: 76.47% (FP32) · 76.47% (INT8)',
          ],
          v2Title: 'v2 Clinical Pipeline (v2-sih.ipynb)',
          v2Points: [
            'Classical 5-Fold Accuracy: 92.5% ± 1.6% (+22.1% improvement)',
            'Classical 5-Fold AUC: 0.972 ± 0.005 (near-perfect class separation)',
            'Clinical Sensitivity / Recall: 92.5% ± 1.6% (catches >92% of early-stage patients)',
            'Precision: 92.4% ± 2.1% · F1 Score: 0.924 ± 0.016',
            'Hybrid Quantum (Shallow): 90.5% ± 1.8% Accuracy · 0.962 ± 0.014 AUC · 92.1% Recall',
            'Early Stopping: patience=15 on validation loss permanently eliminated test-set snooping and overfitting.',
          ],
          accentColor: Colors.green,
        ),
        const SizedBox(height: 24),

        // 5-Fold Summary Matrix Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_rounded, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Exact 5-Fold Cross-Validation Metrics (from Notebooks)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMetricComparisonRow('Accuracy (Mean ± Std)', '70.4% ± 2.7%', '92.5% ± 1.6%'),
              const Divider(height: 14),
              _buildMetricComparisonRow('ROC-AUC (Mean ± Std)', '0.827 ± 0.034', '0.972 ± 0.005'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Sensitivity / Recall (PD)', '55.0% ± 6.8%', '92.5% ± 1.6%'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Precision (PPV)', '79.0% ± 4.4%', '92.4% ± 2.1%'),
              const Divider(height: 14),
              _buildMetricComparisonRow('F1 Score', '0.645 ± 0.044', '0.924 ± 0.016'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildDeepDiveSection(
          theme: theme,
          title: 'The Clinical Importance of 92.5% Sensitivity',
          paragraphs: [
            'In medical triage applications, sensitivity (recall) is the paramount metric. A false positive simply prompts a follow-up consultation with a neurologist, whereas a false negative means a Parkinson\'s patient remains undiagnosed during the vital early-intervention window.',
            'v1 missed 45 out of every 100 Parkinson\'s cases in cross-validation. v2 misses fewer than 8 in 100, while maintaining high 92.4% precision.',
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ACOUSTIC BIOMARKERS DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildAcousticBiomarkersDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          theme: theme,
          badge: 'FEATURE ENGINEERING & QUANTUM MAPPING',
          title: 'Acoustic Biomarkers & Pitch Tremor',
          subtitle:
              'Introducing fundamental frequency F0 pitch tracking and third-formant variance into quantum angle embedding.',
          accentColor: Colors.purple,
          icon: Icons.graphic_eq_rounded,
        ),
        const SizedBox(height: 24),

        _buildSideBySideCard(
          v1Title: 'v1 Features (workbook.ipynb)',
          v1Points: [
            'Extracted candidates: 40 acoustic features',
            'Feature selection: Random Forest on 81 samples',
            'Top 8 selected: mfcc_mean_1, mfcc_std_0, mfcc_std_3, mfcc_std_11, mfcc_std_1, mfcc_std_10, mfcc_std_6, mfcc_std_4',
            'Severe gap: 100% of selected features were purely MFCC cepstral statistics. Completely omitted glottal pitch dynamics, jitter, or fundamental frequency.',
          ],
          v2Title: 'v2 Features (v2-sih.ipynb)',
          v2Points: [
            'Extracted candidates: 40 comprehensive acoustic features (Librosa + Praat)',
            'Feature selection: 300-tree Random Forest on 1,134 samples',
            'Top 8 selected: mfcc_std_1, mfcc_std_3, mfcc_mean_1, mfcc_std_0, mfcc_std_11, mfcc_std_10, f0_mean, mfcc_std_2',
            'NEW Biomarker (f0_mean): Fundamental pitch tracking (Yin algorithm 50-500 Hz). Captures monopitch dysarthria and vocal cord atrophy.',
            'NEW Biomarker (mfcc_std_2): Third-formant resonance fluctuation in oral/pharyngeal tract.',
            'Replaced low-importance features (mfcc_std_6, mfcc_std_4).',
          ],
          accentColor: Colors.purple,
        ),
        const SizedBox(height: 24),

        // Feature Breakdown Grid
        Text(
          'Top 8 Quantum State Embedded Biomarkers in v2',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          'f0_mean (NEW)',
          'Fundamental Frequency Mean',
          'Tracks Parkinsonian monopitch, laryngeal tensor rigidity, and vocal cord thinning. Essential clinical dysphonia biomarker.',
          isNew: true,
        ),
        _buildFeatureItem(
          'mfcc_std_2 (NEW)',
          'MFCC-3 Formant Fluctuation',
          'Measures acoustic resonance bandwidth in the oral and pharyngeal cavities, capturing vocal tract motor spasms.',
          isNew: true,
        ),
        _buildFeatureItem(
          'mfcc_std_1',
          'MFCC-2 Variance',
          'Spectral tilt cycle-to-cycle stability, revealing breathiness vs vocal cord adduction quality.',
        ),
        _buildFeatureItem(
          'mfcc_std_3',
          'MFCC-4 Dispersion',
          'Pharyngeal shape consistency during sustained vowel phonation.',
        ),
        _buildFeatureItem(
          'mfcc_mean_1',
          'MFCC-2 Mean (Formant)',
          'Spectral slope steepness, correlating with bowing of vocal folds and hypophonia.',
        ),
        _buildFeatureItem(
          'mfcc_std_0',
          'MFCC-1 Stability',
          'Subglottic loudness stability across time; detects involuntary volume tremors.',
        ),
        _buildFeatureItem(
          'mfcc_std_11',
          'MFCC-12 Mucosal Perturbation',
          'High-order mucosal wave irregularity sensitive to early sub-clinical motor decline.',
        ),
        _buildFeatureItem(
          'mfcc_std_10',
          'MFCC-11 High Harmonic Irregularity',
          'Glottal chinks and asymmetric vocal fold vibration in high frequency spectrum.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MOBILE EDGE FOOTPRINT DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildMobileEdgeDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          theme: theme,
          badge: 'EDGE DEPLOYMENT & ZERO LATENCY',
          title: 'Mobile Edge Footprint & TorchScript',
          subtitle:
              'Dynamic INT8 quantization yielding 5.32 KB size and 0.24 ms latency with zero accuracy degradation.',
          accentColor: Colors.orange.shade800,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 24),

        _buildSideBySideCard(
          v1Title: 'v1 Pilot (workbook.ipynb)',
          v1Points: [
            'Model: Classical FP32 (4.13 KB) · INT8 (5.32 KB)',
            'Inference Latency: 0.041 ms (FP32) · 0.198 ms (INT8)',
            'Deployability: Test set sensitivity was only 50.0% — not ready for production release.',
            'No TorchScript or on-device mobile bytecode export was produced or verified.',
          ],
          v2Title: 'v2 Clinical Pipeline (v2-sih.ipynb)',
          v2Points: [
            'Model Size: 5.32 KB (INT8 Quantized)',
            'Inference Latency: 0.238 ms (instantaneous edge CPU execution)',
            'Accuracy & AUC: 90.75% Acc · 0.9503 AUC (INT8 matches and slightly exceeds FP32\'s 0.9496 AUC!)',
            'TorchScript Mobile Export: Scripted classical_mobile.pt and classical_quantized_mobile.pt using torch.jit.script.',
            'Verification: On-device mobile forward pass matched FP32 model output with zero divergence (Match: True).',
            'Zero Cloud Dependency: Runs 100% offline on Android (org.pytorch.Module) and iOS.',
          ],
          accentColor: Colors.orange.shade800,
        ),
        const SizedBox(height: 24),

        // Edge Benchmark Specs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Held-Out Test Set: FP32 vs INT8 Quantized (v2-sih.ipynb)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMetricComparisonRow('Model File Size', '4.13 KB (FP32)', '5.32 KB (INT8)'),
              const Divider(height: 14),
              _buildMetricComparisonRow('CPU Latency', '0.055 ms', '0.238 ms'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Test Accuracy', '90.75%', '90.75% (No loss)'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Test ROC-AUC', '0.9496', '0.9503 (+0.0007)'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Test Sensitivity', '84.82%', '86.61% (+1.79%)'),
              const Divider(height: 14),
              _buildMetricComparisonRow('Test Precision', '95.96%', '94.17%'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildDeepDiveSection(
          theme: theme,
          title: 'Offline Screening for Rural & Remote Healthcare',
          paragraphs: [
            'In resource-constrained or rural clinical environments, reliable high-speed internet is often unavailable. The v2 INT8 model is so lightweight (under 6 KB) that it is embedded directly inside the Flutter APK.',
            'Patients can speak into the smartphone microphone, and their voice biomarkers are evaluated entirely on the mobile processor without sending sensitive voice data across the internet.',
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildHeroBanner({
    required ThemeData theme,
    required String badge,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideCard({
    required String v1Title,
    required List<String> v1Points,
    required String v2Title,
    required List<String> v2Points,
    required Color accentColor,
  }) {
    return Column(
      children: [
        // v1 Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'v1 PILOT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v1Title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...v1Points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Arrow down indicator
        Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_downward_rounded, size: 16, color: accentColor),
          ),
        ),
        const SizedBox(height: 12),

        // v2 Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v2 UPGRADE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      v2Title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...v2Points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricComparisonRow(String metric, String v1Val, String v2Val) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            metric,
            style: const TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            v1Val,
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            v2Val,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String code, String title, String desc, {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNew
              ? Colors.purple.withValues(alpha: 0.05)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNew
                ? Colors.purple.withValues(alpha: 0.3)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isNew ? Colors.purple.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isNew ? Colors.purple : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepDiveSection({
    required ThemeData theme,
    required String title,
    required List<String> paragraphs,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (para) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                para,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
