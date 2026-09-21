import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class V2ModelOption {
  final String id;
  final String name;
  final String shortName;
  final String badge;
  final Color badgeColor;
  final String accuracy;
  final String specs;
  final String description;
  final IconData icon;

  const V2ModelOption({
    required this.id,
    required this.name,
    required this.shortName,
    required this.badge,
    required this.badgeColor,
    required this.accuracy,
    required this.specs,
    required this.description,
    required this.icon,
  });
}

class V2ModelRegistry {
  static String activeModelId = 'classical_fp32';

  static const List<V2ModelOption> options = [
    V2ModelOption(
      id: 'classical_fp32',
      name: 'Classical MLP (FP32)',
      shortName: 'Classical FP32',
      badge: 'v2 Baseline',
      badgeColor: Color(0xFF3B82F6),
      accuracy: '100% Test Acc',
      specs: '13.91 KB · 0.44 ms latency',
      description:
          'Deep Neural Network trained on 1,134 recordings across 8 optimal acoustic biomarkers. Serves maximum mathematical precision.',
      icon: Icons.psychology_rounded,
    ),
    V2ModelOption(
      id: 'classical_int8',
      name: 'Classical Edge (INT8 Quantized)',
      shortName: 'Classical Edge INT8',
      badge: 'v2 Ultra-Edge',
      badgeColor: Color(0xFF10B981),
      accuracy: '100% Test Acc',
      specs: '5.32 KB · 0.24 ms latency',
      description:
          'Post-training INT8 quantized weights. Ultra-compact footprint with near-zero latency, built for mobile edge screening.',
      icon: Icons.bolt_rounded,
    ),
    V2ModelOption(
      id: 'hybrid_fp32',
      name: 'Hybrid Quantum VQC (FP32)',
      shortName: 'Hybrid Quantum VQC',
      badge: 'v2 Quantum',
      badgeColor: Color(0xFF8B5CF6),
      accuracy: '96.8% CV Acc',
      specs: '8 Qubits · Variational Circuit',
      description:
          '8-qubit variational quantum circuit with AngleEmbedding & BasicEntanglerLayers for high-dimensional Hilbert space separation.',
      icon: Icons.all_inclusive_rounded,
    ),
    V2ModelOption(
      id: 'hybrid_int8',
      name: 'Hybrid Quantum Edge (Quantized)',
      shortName: 'Hybrid Quantum INT8',
      badge: 'v2 Edge Quantum',
      badgeColor: Color(0xFF06B6D4),
      accuracy: '96.4% CV Acc',
      specs: '23.75 KB · Quantized Hybrid',
      description:
          'Quantum-classical hybrid architecture with INT8 quantized classical dense layers for lightweight edge execution.',
      icon: Icons.hub_rounded,
    ),
  ];

  static V2ModelOption get activeOption {
    return options.firstWhere(
      (opt) => opt.id == activeModelId,
      orElse: () => options.first,
    );
  }

  static V2ModelOption getOption(String id) {
    return options.firstWhere(
      (opt) => opt.id == id,
      orElse: () => options.first,
    );
  }
}

/// Gemini-style modal bottom sheet for model selection
Future<String?> showV2ModelSelectorModal(
  BuildContext context, {
  String? currentModelId,
  ValueChanged<String>? onSelected,
}) async {
  String selected = currentModelId ?? V2ModelRegistry.activeModelId;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final theme = Theme.of(context);
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Gemini Style
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Serving Model',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Serving exclusively from model_v2 checkpoints',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Model cards
              ...V2ModelRegistry.options.map((opt) {
                final isSelected = opt.id == selected;
                return GestureDetector(
                  onTap: () {
                    setModalState(() => selected = opt.id);
                    V2ModelRegistry.activeModelId = opt.id;
                    NeuralVoiceApi.activeModelVariant = opt.id;
                    if (onSelected != null) {
                      onSelected(opt.id);
                    }
                    Navigator.pop(context, opt.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? opt.badgeColor.withValues(alpha: 0.08)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? opt.badgeColor
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio icon
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isSelected
                                ? opt.badgeColor
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Badges
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt.name,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: opt.badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      opt.badge,
                                      style: TextStyle(
                                        color: opt.badgeColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Specs tag
                              Row(
                                children: [
                                  Text(
                                    opt.accuracy,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: opt.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${opt.specs}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Description
                              Text(
                                opt.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );

  return result;
}

/// Compact Gemini-style pill widget for AppBar or headers
class V2ModelSelectorPill extends StatelessWidget {
  final String currentModelId;
  final ValueChanged<String> onSelected;

  const V2ModelSelectorPill({
    super.key,
    required this.currentModelId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final opt = V2ModelRegistry.getOption(currentModelId);

    return InkWell(
      onTap: () => showV2ModelSelectorModal(
        context,
        currentModelId: currentModelId,
        onSelected: onSelected,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: opt.badgeColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 13, color: opt.badgeColor),
            const SizedBox(width: 6),
            Text(
              opt.shortName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gemini-style model card selector for RecordScreen
class V2ModelSelectorCard extends StatelessWidget {
  final String selectedModelId;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const V2ModelSelectorCard({
    super.key,
    required this.selectedModelId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opt = V2ModelRegistry.getOption(selectedModelId);

    return InkWell(
      onTap: enabled
          ? () => showV2ModelSelectorModal(
                context,
                currentModelId: selectedModelId,
                onSelected: onSelected,
              )
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: opt.badgeColor.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: opt.badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(opt.icon, size: 18, color: opt.badgeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: opt.badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          opt.badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: opt.badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${opt.accuracy}  •  ${opt.specs}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Switch',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 14,
                    color: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
