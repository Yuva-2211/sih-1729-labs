import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ReportRecord> _reports = [];
  bool _isLoading = true;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;
  int? _playingReportId;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadReports();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    if (mounted) setState(() => _playerReady = true);
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlayAudio(ReportRecord r) async {
    if (!_playerReady) return;

    if (_playingReportId == r.id) {
      await _player.stopPlayer();
      if (mounted) setState(() => _playingReportId = null);
      return;
    }

    if (r.audioPath == null || !File(r.audioPath!).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio recording not found on device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_player.isPlaying) {
      await _player.stopPlayer();
    }

    setState(() => _playingReportId = r.id);

    try {
      await _player.startPlayer(
        fromURI: r.audioPath!,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          if (mounted) setState(() => _playingReportId = null);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _playingReportId = null);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await ReportDatabase().getAllReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(ReportRecord r) async {
    if (r.id == null) return;
    await ReportDatabase().deleteReport(r.id!);
    await _loadReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':      return const Color(0xFF5F8F6B);
      case 'high':     return const Color(0xFFB85450);
      default:         return const Color(0xFFD4A017);
    }
  }

  IconData _riskIcon(String level) {
    switch (level.toLowerCase()) {
      case 'low':      return Icons.check_circle_outline;
      case 'high':     return Icons.error_outline;
      default:         return Icons.warning_amber_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
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
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all history',
              onPressed: () => _showClearDialog(),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.outlineVariant, height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
          : _reports.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Screening History',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_reports.length} report${_reports.length == 1 ? '' : 's'} stored locally',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryChips(theme),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final r = _reports[index];
                            return _buildReportCard(theme, r, index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          if (index == 1) Navigator.pushReplacementNamed(context, '/record');
          if (index == 2) Navigator.pushReplacementNamed(context, '/report');
        },
      ),
    );
  }

  Widget _buildSummaryChips(ThemeData theme) {
    final high = _reports.where((r) => r.riskLevel == 'high').length;
    final mod  = _reports.where((r) => r.riskLevel == 'moderate').length;
    final low  = _reports.where((r) => r.riskLevel == 'low').length;

    return Row(
      children: [
        if (high > 0) _miniChip('$high High', const Color(0xFFB85450)),
        if (mod > 0)  _miniChip('$mod Mod', const Color(0xFFD4A017)),
        if (low > 0)  _miniChip('$low Low', const Color(0xFF5F8F6B)),
      ],
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReportCard(ThemeData theme, ReportRecord r, int index) {
    final color = _riskColor(r.riskLevel);
    final icon  = _riskIcon(r.riskLevel);

    return Dismissible(
      key: ValueKey(r.id ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(r),
      onDismissed: (_) => _deleteReport(r),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/report',
            arguments: r.toPredictionResult(),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              // Risk icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.riskLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${r.confidencePercent.toStringAsFixed(1)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _formatDate(r.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 10, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    r.patientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(r.llmRecommendation.isNotEmpty ? r.llmRecommendation : r.recommendation).split('.').first}.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.memory_outlined, size: 12, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            r.modelUsed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.outline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${r.latencyMs.toStringAsFixed(0)} ms',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (r.audioPath != null && r.audioPath!.isNotEmpty) ...[
                IconButton(
                  icon: Icon(
                    _playingReportId == r.id
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  tooltip: _playingReportId == r.id ? 'Stop audio' : 'Rehear voice',
                  onPressed: () => _togglePlayAudio(r),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(
                Icons.history_outlined,
                size: 40,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reports Yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record your voice sample to run an acoustic analysis. '
              'Each report is automatically saved here for tracking.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/record'),
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Screening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(ReportRecord r) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Report'),
            content: const Text('Remove this screening report from your history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showClearDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All History'),
        content: const Text(
          'This will permanently delete all saved screening reports. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ReportDatabase().clearAll();
      await _loadReports();
    }
  }
}
