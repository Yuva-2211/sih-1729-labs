import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AnalysisPipelineScreen extends StatefulWidget {
  const AnalysisPipelineScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisPipelineScreen> createState() => _AnalysisPipelineScreenState();
}

class _AnalysisPipelineScreenState extends State<AnalysisPipelineScreen>
    with TickerProviderStateMixin {
  // ---- State --------------------------------------------------------------
  int _currentStep = 0;          // 0 = not started, 1-7 = stages
  double _progress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';
  PredictionResult? _result;

  // ---- Stage labels matching backend pipeline stages ---------------------
  static const List<Map<String, String>> _stages = [
    {'title': 'Loading audio', 'subtitle': 'Reading WAV file'},
    {'title': 'Audio preprocessing', 'subtitle': 'Resampling · Trimming · Normalising'},
    {'title': 'Feature extraction', 'subtitle': 'MFCCs · F0 · Jitter · Shimmer · HNR'},
    {'title': 'Feature selection', 'subtitle': 'Top-8 quantum circuit features'},
    {'title': 'Quantum encoding', 'subtitle': 'Angle embedding → 8-qubit state'},
    {'title': 'Model inference', 'subtitle': 'Hybrid Quantum-Classical VQC'},
    {'title': 'LLM recommendation', 'subtitle': 'Groq Llama 3 generating report...'},
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ---- UI stage simulation timer (stages 1-5 are instant server-side) ----
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Delay slightly so the screen renders before API call starts
    Future.delayed(const Duration(milliseconds: 300), _runPipeline);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _uiTimer?.cancel();
    super.dispose();
  }

  // ---- Pipeline execution -------------------------------------------------

  Future<void> _runPipeline() async {
    // Get the file path passed from RecordScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final filePath = args?['filePath'] as String?;

    if (filePath == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No audio file found. Please record again.';
      });
      return;
    }

    // Animate through stages 1-5 quickly (they happen server-side during the API call)
    _uiTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < 5) {
          _currentStep++;
          _progress = _currentStep / 7.0;
        } else {
          timer.cancel(); // stages 6-7 will be set when API returns
        }
      });
    });

    try {
      // --- Real API call ---
      final result = await NeuralVoiceApi().predictFromAudio(
        filePath,
        modelVariant: 'hybrid_fp32',   // use quantum model
        useLlm: true,
      );

      _uiTimer?.cancel();

      if (mounted) {
        // Animate to stage 6 then 7
        setState(() {
          _currentStep = 6;
          _progress = 6 / 7.0;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _currentStep = 7;
            _progress = 1.0;
            _result = result;
          });
        }

        // Short pause so user sees 100% before navigation
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/result',
            arguments: result,
          );
        }
      }
    } catch (e) {
      _uiTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _uiTimer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back,
                            color: AppColors.onSurfaceVariant, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Cancel Analysis',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'STEP 2 OF 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Analysis Pipeline',
                style: theme.textTheme.headlineLarge
                    ?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Processing your voice through quantum and classical models.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Progress bar
              if (!_hasError) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _hasError ? AppColors.error : AppColors.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(_progress * 100).toInt()}%',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Error state
              if (_hasError)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Analysis Failed',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Stage checklist
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 1, child: _buildStatusChecklist(theme)),
                            const SizedBox(width: 32),
                            Expanded(
                                flex: 2, child: _buildPipelineDiagram(theme)),
                          ],
                        );
                      } else {
                        return ListView(children: [
                          _buildStatusChecklist(theme),
                          const SizedBox(height: 32),
                          _buildPipelineDiagram(theme),
                        ]);
                      }
                    },
                  ),
                ),

              // Abort button
              if (!_hasError)
                Container(
                  padding: const EdgeInsets.only(top: 24),
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {
                      _uiTimer?.cancel();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Abort Analysis'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChecklist(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXECUTION STATUS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _stages.length,
            (i) => _buildChecklistItem(
              theme,
              i + 1,
              _stages[i]['title']!,
              _stages[i]['subtitle']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
      ThemeData theme, int stepNum, String title, String subtitle) {
    final bool isCompleted = _currentStep >= stepNum;
    final bool isActive = _currentStep + 1 == stepNum;
    final bool isPending = stepNum > _currentStep + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          else if (isActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Icon(
                Icons.radio_button_unchecked,
                color: AppColors.outline.withValues(alpha: _pulseAnimation.value),
                size: 20,
              ),
            )
          else
            const Icon(Icons.radio_button_unchecked,
                color: AppColors.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: isPending ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    isActive ? '${subtitle.split('·').first.trim()}...' : subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineDiagram(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARCHITECTURE TOPOLOGY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  _buildNodeBox(theme, Icons.graphic_eq, 'Feature Extraction'),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant),
                  Container(width: 240, height: 1, color: AppColors.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 1, height: 24, color: AppColors.outlineVariant),
                      const SizedBox(width: 238),
                      Container(width: 1, height: 24, color: AppColors.outlineVariant),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedNodeBox(theme, Icons.memory,
                          'Quantum VQC', AppColors.primary),
                      const SizedBox(width: 20),
                      _buildAnimatedNodeBox(theme, Icons.analytics,
                          'Classical MLP', AppColors.secondary),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 1, height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                      const SizedBox(width: 238),
                      Container(width: 1, height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ],
                  ),
                  Container(width: 240, height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  Opacity(
                    opacity: _currentStep >= 6 ? 1.0 : 0.4,
                    child: _buildNodeBox(theme, Icons.smart_toy, 'LLM Report'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeBox(ThemeData theme, IconData icon, String label) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onSurface),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAnimatedNodeBox(
      ThemeData theme, IconData icon, String label, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: color.withValues(alpha: _pulseAnimation.value), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 * (1 - _pulseAnimation.value)),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: _pulseAnimation.value),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PROCESSING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
