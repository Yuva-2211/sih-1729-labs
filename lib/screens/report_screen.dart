import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// ReportScreen — single unified screen for all analysis output
// ---------------------------------------------------------------------------

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  PredictionResult? _result;
  late AnimationController _animController;

  // Audio playback
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;
  bool _playingRaw = false;
  bool _playingProcessed = false;
  String? _rawTempPath;
  String? _procTempPath;

  // Doctor finder (via device location & browser search)
  bool _loadingDoctors = false;

  // Risk colour helpers
  static const Map<String, Color> _riskColors = {
    'low':      Color(0xFF5F8F6B),
    'moderate': Color(0xFFD4A017),
    'high':     Color(0xFFB85450),
  };

  static const Map<String, IconData> _riskIcons = {
    'low':      Icons.check_circle_outline,
    'moderate': Icons.warning_amber_outlined,
    'high':     Icons.error_outline,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    if (mounted) setState(() => _playerReady = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PredictionResult && _result == null) {
      _result = args;
      _animController.forward();
      // Write audio temp files
      _writeAudioFiles(_result!);

      // Fix #8: No longer auto-opens Maps without user consent.
      // For HIGH risk, show a non-disruptive SnackBar nudge instead.
      // The 'Find Nearby Neurologists' button on the report page handles the Maps action.
      if (_result!.riskLevel == 'high') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'High risk detected — consider finding a neurologist nearby.',
                ),
                backgroundColor: const Color(0xFFB85450),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Find',
                  textColor: Colors.white,
                  onPressed: () => _searchDoctorsInBrowser(query: 'neurologist'),
                ),
              ),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _player.closePlayer();
    // Clean up temp files
    if (_rawTempPath != null) {
      try { File(_rawTempPath!).deleteSync(); } catch (_) {}
    }
    if (_procTempPath != null) {
      try { File(_procTempPath!).deleteSync(); } catch (_) {}
    }
    super.dispose();
  }

  // ---- Audio helpers -------------------------------------------------------

  Future<void> _writeAudioFiles(PredictionResult r) async {
    try {
      final dir = await getTemporaryDirectory();
      final id = r.requestId.isNotEmpty
          ? r.requestId.substring(0, min(8, r.requestId.length))
          : 'nv';

      if (r.rawAudioB64.isNotEmpty) {
        final bytes = base64Decode(r.rawAudioB64);
        final path = '${dir.path}/nv_raw_$id.wav';
        await File(path).writeAsBytes(bytes);
        if (mounted) setState(() => _rawTempPath = path);
      }

      if (r.preprocessedAudioB64.isNotEmpty) {
        final bytes = base64Decode(r.preprocessedAudioB64);
        final path = '${dir.path}/nv_proc_$id.wav';
        await File(path).writeAsBytes(bytes);
        if (mounted) setState(() => _procTempPath = path);
      }
    } catch (_) {}
  }

  Future<void> _playAudio(bool isRaw) async {
    if (!_playerReady) return;
    final path = isRaw ? _rawTempPath : _procTempPath;
    if (path == null || !File(path).existsSync()) return;

    // If already playing, stop
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _playingRaw = false;
        _playingProcessed = false;
      });
      return;
    }

    setState(() {
      _playingRaw = isRaw;
      _playingProcessed = !isRaw;
    });

    await _player.startPlayer(
      fromURI: path,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        if (mounted) {
          setState(() {
            _playingRaw = false;
            _playingProcessed = false;
          });
        }
      },
    );
  }

  // ---- Doctor / Specialist Browser Search (Device Location + Browser) -----

  Future<void> _searchDoctorsInBrowser({String query = 'neurologist'}) async {
    setState(() => _loadingDoctors = true);
    try {
      Position? pos;
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 6),
            ),
          );
        }
      } catch (_) {
        // Location failed or permission denied, fallback to generic search
      }

      Uri url;
      if (pos != null) {
        // Center search in Google Maps / Browser at user's exact coordinates
        url = Uri.parse(
          'https://www.google.com/maps/search/$query/@${pos.latitude},${pos.longitude},14z',
        );
      } else {
        url = Uri.parse(
          'https://www.google.com/maps/search/$query+near+me',
        );
      }

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final webUrl = Uri.parse('https://www.google.com/search?q=$query+near+me');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser search: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDoctors = false);
      }
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _result;

    // Empty state — no prediction yet
    if (r == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(theme, null),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq_rounded,
                    size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 24),
                Text(
                  'No Analysis Yet',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Record your voice to run an acoustic analysis.\nYour full report will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/record'),
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildNav(context, 2),
      );
    }

    final riskColor = _riskColors[r.riskLevel] ?? AppColors.primary;
    final riskIcon  = _riskIcons[r.riskLevel] ?? Icons.info_outline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(theme, r),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Risk Summary ─────────────────────────────────────────
                _buildRiskSummary(theme, r, riskColor, riskIcon),
                const SizedBox(height: 20),

                // ── 2. LLM Recommendation ───────────────────────────────────
                _buildLlmCard(theme, r, riskColor),
                const SizedBox(height: 20),

                // ── 3. Waveforms + Playback ──────────────────────────────────
                _buildWaveformSection(theme, r),
                const SizedBox(height: 20),

                // ── 4. Explainability Panel ──────────────────────────────────
                _buildExplainabilityPanel(theme, r),
                const SizedBox(height: 20),

                // ── 5. All Feature Values ────────────────────────────────────
                _buildAllFeaturesGrid(theme, r),
                const SizedBox(height: 20),

                // ── 6. Clinical Metrics ──────────────────────────────────────
                _buildMetricsRow(theme, r),
                const SizedBox(height: 20),

                // ── 7. Doctor Finder (HIGH risk only) ───────────────────────
                if (r.riskLevel == 'high' && r.probability >= 0.65)
                  _buildDoctorSection(theme),

                const SizedBox(height: 20),

                // ── 8. Actions ───────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamedAndRemoveUntil(context, '/record', (_) => false),
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: const Text('Record Again'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/history'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('View History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNav(context, 2),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ThemeData theme, PredictionResult? r) {
    return AppBar(
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
        if (r != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_riskColors[r.riskLevel] ?? AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (_riskColors[r.riskLevel] ?? AppColors.primary)),
                ),
                child: Text(
                  r.riskLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _riskColors[r.riskLevel] ?? AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.outlineVariant, height: 1),
      ),
    );
  }

  // ── 1. Risk Summary ────────────────────────────────────────────────────────

  Widget _buildRiskSummary(ThemeData theme, PredictionResult r,
      Color riskColor, IconData riskIcon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(riskIcon, color: riskColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.riskLabel, style: theme.textTheme.headlineLarge?.copyWith(color: riskColor)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.primaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            r.patientName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.confidencePercent.toStringAsFixed(1)}% PD probability · ${r.modelUsed}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                // Probability bar
                LayoutBuilder(builder: (ctx, c) {
                  return Stack(children: [
                    Container(
                      height: 5,
                      width: c.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) => Container(
                        height: 5,
                        width: c.maxWidth *
                            Curves.easeOutCubic.transform(_animController.value) *
                            r.probability,
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. LLM Recommendation ─────────────────────────────────────────────────

  Widget _buildLlmCard(ThemeData theme, PredictionResult r, Color riskColor) {
    // Only show LLM text — never a fallback static string
    final text = r.llmRecommendation.isNotEmpty
        ? r.llmRecommendation
        : r.recommendation;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.smart_toy_outlined,
                size: 18, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Clinical Recommendation',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️  Screening tool only. Always consult a qualified neurologist for diagnosis.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Waveforms + Playback ───────────────────────────────────────────────

  Widget _buildWaveformSection(ThemeData theme, PredictionResult r) {
    final hasWaveforms = r.rawWaveform.length >= 10 && r.preprocessedWaveform.length >= 10;
    final hasAudio = _rawTempPath != null || _procTempPath != null;

    if (!hasWaveforms) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(theme, Icons.graphic_eq_rounded, 'Voice Signal Analysis'),
            const SizedBox(height: 16),
            Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Waveform data not available\n(backend returned no audio samples)',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.graphic_eq_rounded,
                size: 18, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Voice Signal Analysis',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _legendDot(const Color(0xFF7CA5FF), 'Raw'),
            const SizedBox(width: 8),
            _legendDot(AppColors.primaryContainer, 'Processed'),
          ]),
          Text(
            '${r.rawWaveform.length} samples @ 16 kHz · tap ▶ to listen',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 16),

          // ── Raw waveform ──────────────────────────────────────────────────
          _waveformRow(
            theme: theme,
            label: 'RAW CAPTURED VOICE',
            chart: _lineChart(r.rawWaveform, const Color(0xFF7CA5FF)),
            isPlaying: _playingRaw,
            canPlay: hasAudio && _rawTempPath != null,
            onPlay: () => _playAudio(true),
          ),
          const SizedBox(height: 20),

          // ── Preprocessed waveform ─────────────────────────────────────────
          _waveformRow(
            theme: theme,
            label: 'PREPROCESSED (VAD + NORMALISED)',
            chart: _lineChart(r.preprocessedWaveform, AppColors.primaryContainer),
            isPlaying: _playingProcessed,
            canPlay: hasAudio && _procTempPath != null,
            onPlay: () => _playAudio(false),
          ),
        ],
      ),
    );
  }

  Widget _waveformRow({
    required ThemeData theme,
    required String label,
    required Widget chart,
    required bool isPlaying,
    required bool canPlay,
    required VoidCallback onPlay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.6,
                  fontSize: 10,
                ),
              ),
            ),
            if (canPlay) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onPlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlaying
                          ? AppColors.primaryContainer
                          : AppColors.outlineVariant,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 14,
                      color: isPlaying
                          ? AppColors.primaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPlaying ? 'Stop' : 'Play',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: isPlaying
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(height: 100, child: chart),
      ],
    );
  }

  Widget _lineChart(List<double> samples, Color color) {
    if (samples.isEmpty) return const SizedBox.shrink();
    final maxAmp = samples.map((e) => e.abs()).fold<double>(0.001, max);
    final spots = samples
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value / maxAmp))
        .toList();

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.5,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 1,
        ),
      ),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: -1.1,
      maxY: 1.1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surface,
          tooltipRoundedRadius: 6,
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(3),
                    TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ))
              .toList(),
        ),
      ),
    ));
  }

  // ── 4. Explainability Panel ───────────────────────────────────────────────

  Widget _buildExplainabilityPanel(ThemeData theme, PredictionResult r) {
    if (r.selectedFeatures.isEmpty) return const SizedBox.shrink();

    final sorted = r.selectedFeatures.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final maxVal = sorted.first.value.abs();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(theme, Icons.psychology_outlined, 'Feature Explainability'),
          Text(
            'Tap any feature to understand its clinical significance',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...sorted.map((e) {
            final importance = maxVal > 0 ? (e.value.abs() / maxVal) : 0.0;
            return _explainTile(theme, e.key, e.value, importance, e == sorted.first);
          }),
        ],
      ),
    );
  }

  Widget _explainTile(ThemeData theme, String key, double val,
      double importance, bool isTop) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTop
                ? AppColors.primaryContainer.withValues(alpha: 0.12)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              val.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isTop ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  _humanFeatureName(key),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isTop)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TOP',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryContainer),
                  ),
                ),
            ]),
            const SizedBox(height: 5),
            LayoutBuilder(builder: (ctx, c) => Stack(children: [
              Container(
                height: 4,
                width: c.maxWidth,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 4,
                width: c.maxWidth * importance.clamp(0.04, 1.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ])),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              _featureExplanation(key),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurface, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. All Feature Values ─────────────────────────────────────────────────

  Widget _buildAllFeaturesGrid(ThemeData theme, PredictionResult r) {
    if (r.selectedFeatures.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(theme, Icons.data_array_rounded, 'Acoustic Biomarkers'),
          const SizedBox(height: 4),
          Text(
            'All ${r.selectedFeatures.length} features from model prediction',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: r.selectedFeatures.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _humanFeatureName(e.key),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value.toStringAsFixed(4),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 6. Clinical Metrics ───────────────────────────────────────────────────

  Widget _buildMetricsRow(ThemeData theme, PredictionResult r) {
    return Row(children: [
      Expanded(child: _metricChip(theme, 'Inference', '${r.inferenceLatencyMs.toStringAsFixed(0)} ms')),
      const SizedBox(width: 10),
      Expanded(child: _metricChip(theme, 'Total latency', '${r.latencyMs.toStringAsFixed(0)} ms')),
      const SizedBox(width: 10),
      Expanded(child: _metricChip(theme, 'Session', r.requestId.isNotEmpty ? r.requestId.substring(0, min(8, r.requestId.length)) : '—')),
    ]);
  }

  Widget _metricChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }

  // ── 7. Doctor & Specialist Finder (Browser & Device Location) ─────────────

  Widget _buildDoctorSection(ThemeData theme) {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB85450).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 20,
                      color: Color(0xFFB85450),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Consultation & Specialists',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB85450),
                          ),
                        ),
                        Text(
                          'Elevated risk detected — in-person clinical review recommended',
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
              const SizedBox(height: 14),
              Text(
                'This screening tool is an acoustic biomarker assessment and not a definitive medical diagnosis. For individuals showing elevated acoustic risk indicators or vocal tremor, prompt evaluation by a licensed neurologist or movement disorder specialist is strongly advised.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore_outlined,
                            size: 16, color: AppColors.primaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          'Search Specialists Near You',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search for licensed neurologists and clinics nearest to your current location.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadingDoctors
                            ? null
                            : () => _searchDoctorsInBrowser(
                                query: 'neurologist'),
                        icon: _loadingDoctors
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.location_on_rounded, size: 18),
                        label: const Text(
                          'Search Nearby Neurologists',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB85450),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadingDoctors
                            ? null
                            : () => _searchDoctorsInBrowser(
                                query: 'movement+disorder+clinic'),
                        icon: const Icon(Icons.medical_information_outlined,
                            size: 18),
                        label: const Text(
                          'Search Movement Disorder Clinics',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildNav(BuildContext context, int index) {
    return CustomBottomNavBar(
      currentIndex: index,
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, '/');
        if (i == 1) Navigator.pushReplacementNamed(context, '/record');
        if (i == 3) Navigator.pushReplacementNamed(context, '/history');
      },
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primaryContainer),
      const SizedBox(width: 8),
      Text(title,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
    ]);
  }

  String _humanFeatureName(String key) {
    const labels = {
      'mfcc_mean_0': 'MFCC-1 Mean',
      'mfcc_mean_1': 'MFCC-2 Mean (Formant)',
      'mfcc_std_0': 'MFCC-1 Stability',
      'mfcc_std_1': 'MFCC-2 Variance',
      'mfcc_std_2': 'MFCC-3 Formant Fluctuation',
      'mfcc_std_3': 'MFCC-4 Dispersion',
      'mfcc_std_4': 'MFCC-5 Spectral Slope',
      'mfcc_std_6': 'MFCC-7 Micro-Tremor',
      'mfcc_std_10': 'MFCC-11 High Harmonic',
      'mfcc_std_11': 'MFCC-12 High Harmonic',
      'jitter_local': 'Pitch Jitter',
      'shimmer_local': 'Amplitude Shimmer',
      'hnr': 'Harmonics-to-Noise Ratio',
      'f0_mean': 'Fundamental Pitch (F0)',
      'zcr': 'Zero Crossing Rate',
      'spec_centroid': 'Spectral Centroid',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  String _featureExplanation(String key) {
    const explanations = {
      'mfcc_mean_1':
          '【MFCC-2 Mean (Spectral Tilt)】\n'
          '• Disease Perspective: In Parkinson\'s Disease (PD), incomplete vocal cord adduction (bowed vocal folds) and hypophonia flatten the spectral slope, reducing lower harmonic resonance.\n'
          '• Healthy vs PD: Healthy phonation produces strong glottal closure and steep harmonic decay. PD speech shows flattened spectral energy and voice breathiness.',
      'mfcc_std_0':
          '【MFCC-1 Stability (Overall Acoustic Energy)】\n'
          '• Disease Perspective: Measures overall loudness stability. Basal ganglia impairment reduces respiratory muscle coordination, causing subglottic pressure instability and vocal tremors.\n'
          '• Healthy vs PD: Healthy individuals maintain uniform volume (low std). PD patients show high standard deviation due to involuntary loudness dropouts and tremor.',
      'mfcc_std_1':
          '【MFCC-2 Variance (Spectral Tilt Fluctuation)】\n'
          '• Disease Perspective: Reflects cycle-to-cycle stability of spectral balance. Laryngeal muscle rigidity and rapid thyroarytenoid fatigue cause rapid shifts in timbre.\n'
          '• Healthy vs PD: Healthy voices maintain consistent timbre throughout phonation; PD phonation erratically fluctuates between strained and breathy acoustic qualities.',
      'mfcc_std_2':
          '【MFCC-3 Formant Fluctuation (Vocal Tract Resonance)】\n'
          '• Disease Perspective: Captures acoustic resonance bandwidth in the oral and pharyngeal cavities. Dysdiadochokinesia and vocal tract muscular rigidity destabilize third-formant resonance.\n'
          '• Healthy vs PD: Well-anchored harmonic resonance in controls; unsteady formant bandwidth variance in PD subjects.',
      'mfcc_std_3':
          '【MFCC-4 Dispersion (Formant & Resonance)】\n'
          '• Disease Perspective: Captures pharyngeal cavity shape stability. Hypokinetic dysarthria causes rigidity in the tongue and pharynx, preventing steady vowel formant retention.\n'
          '• Healthy vs PD: Formants remain anchored in healthy sustained /a/ phonation; in PD, involuntary articulatory spasms disperse formant energy.',
      'mfcc_std_4':
          '【MFCC-5 Spectral Slope Instability】\n'
          '• Disease Perspective: Reflects fine mid-to-high frequency acoustic damping. In early PD, laryngeal tensor muscles fail to sustain isometric tension.\n'
          '• Healthy vs PD: Flat, uniform high-frequency response in controls; irregular variance in early-stage Parkinsonian dysarthria.',
      'mfcc_std_6':
          '【MFCC-7 Micro-Tremor】\n'
          '• Disease Perspective: Correlates with resting/postural laryngeal micro-tremors (4–7 Hz) typical of Parkinsonian motor disturbances.\n'
          '• Healthy vs PD: Minimal perturbation in healthy controls; distinctly elevated in PD as neuromuscular tremor pulses through the vocal cords.',
      'mfcc_std_10':
          '【MFCC-11 High-Order Harmonic Irregularity】\n'
          '• Disease Perspective: High-order cepstral variations reflect mucosal wave asymmetry and turbulent friction noise intermingled with high harmonics.\n'
          '• Healthy vs PD: Smooth harmonic roll-off in healthy voices; irregular fluctuations in PD caused by glottal chinks and asymmetric vocal fold vibration.',
      'mfcc_std_11':
          '【MFCC-12 High-Order Micro-Perturbation】\n'
          '• Disease Perspective: Captures subtle mucosal wave irregularities and air turbulence leakage. Sensitive in prodromal stages before motor symptoms become severe.\n'
          '• Healthy vs PD: Low and stable in healthy controls; shows erratic perturbation spikes in PD.',
      'jitter_local':
          '【Pitch Jitter (Frequency Instability)】\n'
          '• Disease Perspective: Cycle-to-cycle pitch period fluctuation. Caused by loss of dopamine in the basal ganglia disrupting recurrent laryngeal nerve motor timing.\n'
          '• Healthy vs PD: Healthy voices exhibit < 1.04% jitter. PD voices frequently exceed 1.5%–3.5%, manifesting as audible vocal tremor and pitch instability.',
      'shimmer_local':
          '【Amplitude Shimmer (Volume Instability)】\n'
          '• Disease Perspective: Cycle-to-cycle sound wave amplitude perturbation. Inconsistent subglottic air pressure and incomplete glottal adduction cause volume flutter.\n'
          '• Healthy vs PD: Healthy voices exhibit < 3.81% shimmer. PD voices frequently reach 5%–12%, causing audible volume instability and vocal weakness.',
      'hnr':
          '【Harmonics-to-Noise Ratio (Voice Clarity)】\n'
          '• Disease Perspective: Ratio of clean harmonic vocal sound to turbulent noise. Glottal incompetence in PD allows unvibrated air to leak through the vocal folds.\n'
          '• Healthy vs PD: Healthy voice typically > 20 dB (resonant, crisp). PD voices often drop below 12–16 dB (hoarse, breathy dysphonia).',
      'f0_mean':
          '【Fundamental Frequency / Pitch (F0)】\n'
          '• Disease Perspective: Parkinsonian hypokinetic dysarthria produces severe monopitch (reduced pitch variability) accompanied by localized pitch tremors.\n'
          '• Healthy vs PD: Healthy speakers have natural dynamic pitch control; PD patients exhibit a characteristically flat, monotonic voice.',
      'zcr':
          '【Zero Crossing Rate】\n'
          '• Disease Perspective: Measures frequency of sign changes in the waveform. Elevated ZCR indicates turbulent friction noise overtaking harmonic voice.\n'
          '• Healthy vs PD: Low in clean voiced vowel phonation; elevated in PD due to breathy air leakage.',
      'spec_centroid':
          '【Spectral Centroid (Vocal Brightness)】\n'
          '• Disease Perspective: Center of mass of the frequency spectrum. Hypophonia in PD shifts energy downward, resulting in a dull, muffled acoustic signature.\n'
          '• Healthy vs PD: Healthy speakers produce bright resonant frequencies; PD speech shows dampened high-frequency acoustic brightness.',
    };
    return explanations[key] ?? 'This acoustic biomarker contributes to the overall PD risk assessment.';
  }
}
