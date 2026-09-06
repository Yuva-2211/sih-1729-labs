import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalysisPipelineScreen extends StatefulWidget {
  const AnalysisPipelineScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisPipelineScreen> createState() => _AnalysisPipelineScreenState();
}

class _AnalysisPipelineScreenState extends State<AnalysisPipelineScreen> with TickerProviderStateMixin {
  int _currentStep = 3; // 1, 2, 3 completed, 4 in progress
  double _progress = 0.65;
  Timer? _simTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Simulate progress
    _simTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < 5) {
          _currentStep++;
          _progress = _currentStep == 4 ? 0.85 : 1.0;
        } else {
          timer.cancel();
          // Navigate to result
          Navigator.pushReplacementNamed(context, '/result');
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simTimer?.cancel();
    super.dispose();
  }

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
                      _simTimer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant, size: 20),
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
                style: theme.textTheme.headlineLarge?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Processing acoustic data through quantum and classical models.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
              
              // Content Grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 600;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildStatusChecklist(theme)),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: _buildPipelineDiagram(theme)),
                        ],
                      );
                    } else {
                      return ListView(
                        children: [
                          _buildStatusChecklist(theme),
                          const SizedBox(height: 32),
                          _buildPipelineDiagram(theme),
                        ],
                      );
                    }
                  },
                ),
              ),
              
              // Bottom Action
              Container(
                padding: const EdgeInsets.only(top: 24),
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    _simTimer?.cancel();
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
          _buildChecklistItem(theme, 1, 'Audio captured', '10.2s sample · 44.1kHz'),
          _buildChecklistItem(theme, 2, 'Signal cleaned', 'Noise reduction applied'),
          _buildChecklistItem(theme, 3, 'Features extracted', 'MFCCs & Spectrogram generated'),
          _buildChecklistItem(theme, 4, 'Model Inference', 'Processing...', isPulse: true),
          _buildChecklistItem(theme, 5, 'Result Aggregation', 'Pending', isPending: true),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ThemeData theme, int stepNum, String title, String subtitle, {bool isPulse = false, bool isPending = false}) {
    bool isCompleted = _currentStep >= stepNum;
    bool isActive = _currentStep + 1 == stepNum;
    
    if (isPending && isActive) {
      isPulse = true;
      isPending = false;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          else if (isActive || isPulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Icon(Icons.radio_button_unchecked, color: AppColors.outline.withValues(alpha: _pulseAnimation.value), size: 20);
              }
            )
          else
            const Icon(Icons.radio_button_unchecked, color: AppColors.outline, size: 20),
            
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
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: (isActive || isPulse) ? AppColors.primary : AppColors.onSurfaceVariant,
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
                    _buildAnimatedNodeBox(theme, Icons.memory, 'Quantum Processing', AppColors.primary),
                    const SizedBox(width: 20), // Spacing
                    _buildAnimatedNodeBox(theme, Icons.analytics, 'Classical Processing', AppColors.secondary),
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
                  opacity: 0.5,
                  child: _buildNodeBox(theme, Icons.merge_type, 'Ensemble Inference', isDashed: true),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeBox(ThemeData theme, IconData icon, String label, {bool isDashed = false}) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.surfaceVariant,
          style: isDashed ? BorderStyle.none : BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.onSurface),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNodeBox(ThemeData theme, IconData icon, String label, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: _pulseAnimation.value), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 * (1 - _pulseAnimation.value)),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
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
              )
            ],
          ),
        );
      }
    );
  }
}
