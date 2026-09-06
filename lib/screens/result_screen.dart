import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _confidenceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _confidenceAnimation = Tween<double>(begin: 0.0, end: 94.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const customGreen = Color(0xFF5F8F6B);
    
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
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant,
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // Result Header
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.95 + (0.05 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'Low likelihood',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: customGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _confidenceAnimation,
                        builder: (context, child) {
                          return Row(
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
                                ' confidence',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Divider(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 24),
                      
                      // Info Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 600;
                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: _buildInfoCard(
                                  theme,
                                  Icons.memory,
                                  'Model used',
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Quantum (VQC)',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.primaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: _buildInfoCard(
                                  theme,
                                  Icons.insights,
                                  'Key influencing features',
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildListItem(theme, '1', 'Jitter (local)', false),
                                      _buildListItem(theme, '2', 'Shimmer (apq3)', true),
                                      _buildListItem(theme, '3', 'HNR', true),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      
                      const SizedBox(height: 48),
                      // Action Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/detail');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View detailed explanation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: AppColors.onPrimary, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80), // For bottom nav
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
          if (index == 2) Navigator.pushReplacementNamed(context, '/analysis');
        },
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, IconData icon, String title, Widget content) {
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
              Text(
                title,
                style: theme.textTheme.headlineMedium,
              ),
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

  Widget _buildListItem(ThemeData theme, String index, String text, bool hasTopBorder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: hasTopBorder ? Border(top: BorderSide(color: AppColors.surfaceVariant)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
