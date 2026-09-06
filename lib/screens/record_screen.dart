import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with TickerProviderStateMixin {
  bool isRecording = false;
  bool isComplete = false;
  int seconds = 0;
  Timer? timer;
  Timer? waveformTimer;
  final Random random = Random();
  late List<double> waveformHeights;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    waveformHeights = List.generate(10, (index) => 4.0);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    waveformTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      if (isRecording) {
        // Stop recording
        isRecording = false;
        isComplete = true;
        timer?.cancel();
        waveformTimer?.cancel();
        _pulseController.stop();
        _pulseController.reset();
        
        // Reset waveform
        waveformHeights = List.generate(10, (index) => 4.0);
      } else {
        // Start recording
        isRecording = true;
        isComplete = false;
        seconds = 0;
        
        _pulseController.repeat(reverse: true);
        
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            seconds++;
          });
        });
        
        waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          setState(() {
            waveformHeights = List.generate(10, (index) {
              return 4.0 + random.nextDouble() * 24.0;
            });
          });
        });
      }
    });
  }

  String get timerText {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

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
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timerText,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: isRecording ? AppColors.error : AppColors.onSurface,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
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
                                  ? AppColors.primaryContainer.withValues(alpha: 0.1) 
                                  : AppColors.surfaceContainerLow,
                              border: Border.all(
                                color: isRecording ? AppColors.primaryContainer : AppColors.outlineVariant,
                                width: isRecording ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.mic_rounded,
                              size: 48,
                              color: isRecording ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 4,
                              height: waveformHeights[index],
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isRecording ? AppColors.primaryContainer : AppColors.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text(
                        isComplete 
                            ? 'Recording complete. Proceed to next step.' 
                            : isRecording 
                                ? 'Recording in progress...' 
                                : 'Speak naturally for about 10 seconds.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isComplete) {
                              Navigator.pushNamed(context, '/analysis');
                            } else {
                              _toggleRecording();
                            }
                          },
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
                                ? 'Next step' 
                                : isRecording 
                                    ? 'Stop recording' 
                                    : 'Start recording',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isRecording ? AppColors.error : AppColors.onPrimary,
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
