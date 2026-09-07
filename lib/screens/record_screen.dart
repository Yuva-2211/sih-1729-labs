import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with TickerProviderStateMixin {
  // ---- Recording state ----------------------------------------------------
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  bool isRecording = false;
  bool isComplete = false;
  String? _recordedFilePath;

  // ---- Timer & waveform ---------------------------------------------------
  int seconds = 0;
  Timer? _timer;
  Timer? _waveformTimer;
  final Random random = Random();
  late List<double> waveformHeights;

  // ---- Animations ---------------------------------------------------------
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ---- Minimum recording time (seconds) -----------------------------------
  static const int _minSeconds = 5;

  @override
  void initState() {
    super.initState();
    waveformHeights = List.generate(10, (_) => 4.0);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice analysis.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ---- Recording controls -------------------------------------------------

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'neurovoice_${DateTime.now().millisecondsSinceEpoch}.wav');

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      isRecording = true;
      isComplete = false;
      seconds = 0;
      _recordedFilePath = path;
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => seconds++);
    });

    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() {
        waveformHeights = List.generate(10, (_) => 4.0 + random.nextDouble() * 24.0);
      });
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      isRecording = false;
      isComplete = true;
      waveformHeights = List.generate(10, (_) => 4.0);
    });

    if (seconds < _minSeconds) {
      setState(() {
        isComplete = false;
        _recordedFilePath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording too short. Please record at least $_minSeconds seconds.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleRecording() {
    if (!_recorderReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not ready. Check permissions.')),
      );
      return;
    }
    if (isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _proceed() {
    if (_recordedFilePath == null || !isComplete) return;
    Navigator.pushNamed(
      context,
      '/analysis',
      arguments: {'filePath': _recordedFilePath},
    );
  }

  String get timerText {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NeuroVoice',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'STEP 1 OF 3',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Speak the sustained vowel /aaah/ for 5–10 seconds.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      // Timer display
                      Text(
                        timerText,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: isRecording
                              ? AppColors.error
                              : AppColors.onSurface,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Mic button
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRecording
                                  ? AppColors.primaryContainer
                                      .withValues(alpha: 0.1)
                                  : AppColors.surfaceContainerLow,
                              border: Border.all(
                                color: isRecording
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant,
                                width: isRecording ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              size: 48,
                              color: isRecording
                                  ? AppColors.error
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Waveform
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 4,
                              height: waveformHeights[index],
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isRecording
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Status text
                      Text(
                        isComplete
                            ? '✓ Recording complete (${seconds}s). Tap Next to analyse.'
                            : isRecording
                                ? 'Recording... say /aaah/ continuously.'
                                : _recorderReady
                                    ? 'Tap the mic to start recording.'
                                    : 'Requesting microphone access...',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isComplete
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isComplete
                              ? _proceed
                              : (_recorderReady ? _toggleRecording : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRecording
                                ? AppColors.surfaceContainerHighest
                                : AppColors.primaryContainer,
                            foregroundColor: isRecording
                                ? AppColors.error
                                : AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isComplete
                                ? 'Next — Analyse voice'
                                : isRecording
                                    ? 'Stop recording'
                                    : 'Start recording',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  isRecording ? AppColors.error : AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
        ),
      ),
    );
  }
}
