import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';

// ---------------------------------------------------------------------------
// API Configuration
// ---------------------------------------------------------------------------

class ApiConfig {
  static String? _resolvedBaseUrl;

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Candidate URLs to probe for local development
  static List<String> get candidateUrls {
    if (kIsWeb) return const ['http://127.0.0.1:8000'];
    if (Platform.isAndroid) {
      return const [
        'http://127.0.0.1:8000',      // Physical device (with adb reverse)
        'http://localhost:8000',      // Alternative localhost
        'http://10.0.2.2:8000',        // Android Emulator
        'http://10.233.29.227:8000',   // Current Wi-Fi network IP
      ];
    }
    return const ['http://127.0.0.1:8000'];
  }

  /// Dynamically resolves default backend host based on execution platform.
  static String get baseUrl {
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      return _resolvedBaseUrl!;
    }
    return candidateUrls.first;
  }

  static const Duration timeout = Duration(seconds: 60);
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class PredictionResult {
  final String requestId;
  final double probability;
  final String riskLevel; // 'low' | 'moderate' | 'high'
  final String recommendation;
  final String llmRecommendation;
  final Map<String, double> selectedFeatures;
  final double inferenceLatencyMs;
  final double latencyMs;
  final String modelUsed;
  // Waveform snapshots (200 samples each) — empty list if from DB/fallback
  final List<double> rawWaveform;
  final List<double> preprocessedWaveform;
  // Base64-encoded WAV audio for in-app playback
  final String rawAudioB64;
  final String preprocessedAudioB64;
  final String patientName;

  PredictionResult({
    required this.requestId,
    required this.probability,
    required this.riskLevel,
    required this.recommendation,
    required this.llmRecommendation,
    required this.selectedFeatures,
    required this.inferenceLatencyMs,
    required this.latencyMs,
    required this.modelUsed,
    this.rawWaveform = const [],
    this.preprocessedWaveform = const [],
    this.rawAudioB64 = '',
    this.preprocessedAudioB64 = '',
    this.patientName = 'Participant',
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    Map<String, double> featuresMap = {};
    if (json['selected_features'] is Map) {
      (json['selected_features'] as Map).forEach((key, val) {
        if (val is num) {
          featuresMap[key.toString()] = val.toDouble();
        }
      });
    }

    List<double> parseWaveform(dynamic raw) {
      if (raw is List) return raw.map((e) => (e as num).toDouble()).toList();
      return const [];
    }

    final prob = (json['probability'] as num?)?.toDouble() ?? 0.0;
    final inferLat = (json['inference_latency_ms'] as num?)?.toDouble() ??
        (json['latency_ms'] as num?)?.toDouble() ??
        0.0;
    final totLat = (json['latency_ms'] as num?)?.toDouble() ?? inferLat;

    return PredictionResult(
      requestId: json['request_id']?.toString() ?? '',
      probability: prob.clamp(0.0, 1.0),
      riskLevel: json['risk_level']?.toString() ?? 'moderate',
      recommendation: json['recommendation']?.toString() ?? '',
      llmRecommendation: json['llm_recommendation']?.toString() ??
          json['recommendation']?.toString() ??
          '',
      selectedFeatures: featuresMap,
      inferenceLatencyMs: inferLat,
      latencyMs: totLat,
      modelUsed: json['model_used']?.toString() ?? 'classical_fp32',
      rawWaveform: parseWaveform(json['raw_waveform']),
      preprocessedWaveform: parseWaveform(json['preprocessed_waveform']),
      rawAudioB64: json['raw_audio_b64']?.toString() ?? '',
      preprocessedAudioB64: json['preprocessed_audio_b64']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Participant',
    );
  }

  /// Convert riskLevel to a human-readable label
  String get riskLabel {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'Low likelihood';
      case 'moderate':
        return 'Moderate likelihood';
      case 'high':
        return 'High likelihood';
      default:
        return 'Moderate likelihood';
    }
  }

  /// Confidence % to display
  double get confidencePercent => probability * 100;
}

class ModelsStatus {
  final bool classicalFp32;
  final bool classicalInt8;
  final bool hybridFp32;
  final bool hybridInt8;
  final List<String> selectedFeatures;
  final String modelDir;

  ModelsStatus({
    required this.classicalFp32,
    required this.classicalInt8,
    required this.hybridFp32,
    required this.hybridInt8,
    required this.selectedFeatures,
    required this.modelDir,
  });

  factory ModelsStatus.fromJson(Map<String, dynamic> json) {
    return ModelsStatus(
      classicalFp32: json['classical_fp32'] == true,
      classicalInt8: json['classical_int8'] == true,
      hybridFp32: json['hybrid_fp32'] == true,
      hybridInt8: json['hybrid_int8'] == true,
      selectedFeatures: (json['selected_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modelDir: json['model_dir']?.toString() ?? '',
    );
  }

  bool get anyModelAvailable =>
      classicalFp32 || classicalInt8 || hybridFp32 || hybridInt8;
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class NeuralVoiceApi {
  static final NeuralVoiceApi _instance = NeuralVoiceApi._internal();
  factory NeuralVoiceApi() => _instance;
  NeuralVoiceApi._internal();

  /// Global cached latest inference result for the session
  static PredictionResult? latestResult;

  /// Path to the most recently recorded/analysed audio file
  static String? latestAudioPath;

  /// Active serving model variant (exclusively from model_v2)
  static String activeModelVariant = 'classical_fp32';

  String get _base => ApiConfig.baseUrl;

  // ---- Probe candidate hosts ----------------------------------------------

  Future<String?> _probeWorkingHost() async {
    debugPrint('[NeuralVoiceApi] Probing candidates: ${ApiConfig.candidateUrls}');
    final futures = ApiConfig.candidateUrls.map((host) async {
      try {
        final uri = Uri.parse('$host/api/v1/health');
        final resp = await http.get(uri).timeout(const Duration(seconds: 3));
        if (resp.statusCode == 200) {
          debugPrint('[NeuralVoiceApi] Success reaching: $host');
          return host;
        }
      } catch (e) {
        debugPrint('[NeuralVoiceApi] Could not reach $host: $e');
      }
      return null;
    });

    final results = await Future.wait(futures);
    for (final host in results) {
      if (host != null) {
        ApiConfig.setBaseUrl(host);
        debugPrint('[NeuralVoiceApi] Active backend resolved to: $host');
        return host;
      }
    }
    debugPrint('[NeuralVoiceApi] All candidate hosts unreachable');
    return null;
  }

  // ---- Health check -------------------------------------------------------

  Future<bool> isHealthy() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/api/v1/health'))
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) return true;
    } catch (_) {}

    final foundHost = await _probeWorkingHost();
    return foundHost != null;
  }

  // ---- Models status ------------------------------------------------------

  Future<ModelsStatus?> getModelsStatus() async {
    try {
      debugPrint('[NeuralVoiceApi] Fetching models status from $_base/api/v1/models');
      final resp = await http
          .get(Uri.parse('$_base/api/v1/models'))
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        debugPrint('[NeuralVoiceApi] Models status successfully fetched from $_base');
        return ModelsStatus.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      debugPrint('[NeuralVoiceApi] Error getting models status from $_base: $e');
      final foundHost = await _probeWorkingHost();
      if (foundHost != null) {
        try {
          final resp = await http
              .get(Uri.parse('$foundHost/api/v1/models'))
              .timeout(const Duration(seconds: 3));
          if (resp.statusCode == 200) {
            debugPrint('[NeuralVoiceApi] Models status retrieved from probed host: $foundHost');
            return ModelsStatus.fromJson(jsonDecode(resp.body));
          }
        } catch (err2) {
          debugPrint('[NeuralVoiceApi] Error fetching models from $foundHost: $err2');
        }
      }
    }
    return null;
  }

  // ---- Predict from audio file --------------------------------------------

  Future<PredictionResult> _executeAudioUpload(
    String host,
    String filePath,
    String modelVariant,
    bool useLlm, {
    String patientName = 'Participant',
  }) async {
    final uri = Uri.parse('$host/api/v1/predict').replace(queryParameters: {
      'model_variant': modelVariant,
      'use_llm': useLlm.toString(),
      'patient_name': patientName,
    });

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: 'voice_sample.wav',
      ),
    );

    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final res = PredictionResult.fromJson(jsonDecode(response.body));
      latestResult = res;
      latestAudioPath = filePath;
      // Auto-save to local SQLite database
      try {
        await ReportDatabase().saveReport(res, audioPath: filePath);
      } catch (_) {} // Never let DB errors break the prediction flow
      return res;
    } else {
      String detail = 'Unknown server error (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          detail = body['detail'].toString();
        }
      } catch (_) {}

      if (response.statusCode == 422) {
        throw Exception(detail);
      }
      throw Exception('Server error (${response.statusCode}): $detail');
    }
  }

  Future<PredictionResult> predictFromAudio(
    String filePath, {
    String? modelVariant,
    bool useLlm = true,
    String patientName = 'Participant',
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Audio file not found at: $filePath');
    }

    final variant = modelVariant ?? activeModelVariant;

    try {
      return await _executeAudioUpload(
        _base,
        filePath,
        variant,
        useLlm,
        patientName: patientName,
      );
    } catch (e) {
      final newHost = await _probeWorkingHost();
      if (newHost != null && newHost != _base) {
        return await _executeAudioUpload(
          newHost,
          filePath,
          variant,
          useLlm,
          patientName: patientName,
        );
      }
      rethrow;
    }
  }

  // ---- Predict from feature vector ----------------------------------------

  Future<PredictionResult> predictFromFeatures(
    Map<String, double> features, {
    String? modelVariant,
  }) async {
    final variant = modelVariant ?? activeModelVariant;
    final bodyJson = jsonEncode({
      'features': features,
      'model_variant': variant,
    });

    Future<PredictionResult> post(String host) async {
      final uri = Uri.parse('$host/api/v1/predict/features');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: bodyJson,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final res = PredictionResult.fromJson(jsonDecode(response.body));
        latestResult = res;
        try {
          await ReportDatabase().saveReport(res);
        } catch (_) {}
        return res;
      } else {
        String detail = 'Unknown server error';
        try {
          final b = jsonDecode(response.body);
          if (b is Map && b.containsKey('detail')) detail = b['detail'].toString();
        } catch (_) {}
        throw Exception('Feature Predict Error: $detail');
      }
    }

    try {
      return await post(_base);
    } catch (e) {
      final newHost = await _probeWorkingHost();
      if (newHost != null && newHost != _base) {
        return await post(newHost);
      }
      rethrow;
    }
  }
}
