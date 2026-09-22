import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/v2_model_selector.dart';

class RecordScreen extends StatefulWidget {
  final void Function(dynamic result)? onScreeningDone;

  const RecordScreen({
    super.key,
    this.onScreeningDone,
  });

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

  // ---- Participant Name ---------------------------------------------------
  final TextEditingController _nameController = TextEditingController();

  // ---- Animations ---------------------------------------------------------
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ---- Minimum recording time (seconds) -----------------------------------
  static const int _minSeconds = 5;

  // ---- Model Variant Selection -------------------------------------------
  String _selectedModelVariant = NeuralVoiceApi.activeModelVariant;
  final bool _useLlm = true;

  @override
  void initState() {
    super.initState();
    waveformHeights = List.generate(12, (_) => 4.0);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initRecorder();
  }

  Future<void> _initRecorder() async {
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
    _nameController.dispose();
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

    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      setState(() {
        waveformHeights = List.generate(12, (_) => 4.0 + random.nextDouble() * 30.0);
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
      waveformHeights = List.generate(12, (_) => 4.0);
    });

    if (seconds < _minSeconds) {
      setState(() {
        isComplete = false;
        _recordedFilePath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording must be at least $_minSeconds seconds long for acoustic tremor evaluation.'),
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
    final patientName = _nameController.text.trim().isEmpty ? 'Participant' : _nameController.text.trim();
    
    Navigator.pushNamed(
      context,
      '/pipeline',
      arguments: {
        'filePath': _recordedFilePath,
        'modelVariant': _selectedModelVariant,
        'useLlm': _useLlm,
        'patientName': patientName,
      },
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
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Voice Recording',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 14, color: AppColors.primaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      _recorderReady ? '16 kHz PCM' : 'Init...',
                      style: const TextStyle(
                        color: AppColors.primaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Clean Participant Name Field ────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _nameController,
                  enabled: !isRecording,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person_outline_rounded, color: AppColors.onSurfaceVariant, size: 20),
                    hintText: 'Participant Name (Optional)',
                    hintStyle: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Instructions ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryContainer, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Take a deep breath and hold the vowel sound /aaah/ steadily for 5 to 10 seconds.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 3. Visualizer & Mic Centerpiece ─────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isRecording ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRecording
                                ? Colors.red.withValues(alpha: 0.12)
                                : isComplete
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : AppColors.primaryContainer.withValues(alpha: 0.1),
                            border: Border.all(
                              color: isRecording
                                  ? Colors.red
                                  : isComplete
                                      ? Colors.green
                                      : AppColors.primaryContainer,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isRecording
                                        ? Colors.red
                                        : AppColors.primaryContainer)
                                    .withValues(alpha: isRecording ? 0.25 : 0.12),
                                blurRadius: 28,
                                spreadRadius: isRecording ? 6 : 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRecording
                                    ? Icons.stop_rounded
                                    : isComplete
                                        ? Icons.check_rounded
                                        : Icons.mic_rounded,
                                size: 48,
                                color: isRecording
                                    ? Colors.red
                                    : isComplete
                                        ? Colors.green
                                        : AppColors.primaryContainer,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timerText,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isRecording ? Colors.red : AppColors.onSurface,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Animated Waveform Bars ──────────────────────────────────
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: waveformHeights.map((h) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: 4,
                      height: isRecording ? h : 4.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isRecording
                            ? Colors.redAccent
                            : isComplete
                                ? Colors.green
                                : AppColors.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Status message
              Text(
                isComplete
                    ? '✓ Recording complete (${seconds}s) · Ready for analysis'
                    : isRecording
                        ? 'Recording... hold /aaah/ steadily'
                        : _recorderReady
                            ? 'Tap the circle or button below to start'
                            : 'Preparing audio hardware...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isComplete || isRecording ? FontWeight.w600 : FontWeight.normal,
                  color: isComplete
                      ? Colors.green.shade700
                      : isRecording
                          ? Colors.red.shade700
                          : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // ── 4. Model Selector (Retained per user preference) ───────
              V2ModelSelectorCard(
                selectedModelId: _selectedModelVariant,
                enabled: !isRecording,
                onSelected: (id) {
                  setState(() {
                    _selectedModelVariant = id;
                    NeuralVoiceApi.activeModelVariant = id;
                    V2ModelRegistry.activeModelId = id;
                  });
                },
              ),
              const SizedBox(height: 24),

              // ── 5. Main Action Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isComplete
                      ? _proceed
                      : (_recorderReady ? _toggleRecording : null),
                  icon: Icon(
                    isComplete
                        ? Icons.arrow_forward_rounded
                        : isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isComplete
                        ? 'Run Clinical Analysis'
                        : isRecording
                            ? 'Stop Recording'
                            : 'Start Recording',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording
                        ? Colors.red
                        : isComplete
                            ? Colors.green.shade700
                            : AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
