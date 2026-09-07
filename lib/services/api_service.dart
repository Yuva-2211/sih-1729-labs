import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// API Configuration
// ---------------------------------------------------------------------------

class ApiConfig {
  // For Android emulator use: 'http://10.0.2.2:8000'
  // For iOS simulator use:    'http://127.0.0.1:8000'
  // For physical device use:  'http://<YOUR_MAC_IP>:8000'
  static const String baseUrl = 'http://127.0.0.1:8000';
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
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      requestId: json['request_id'] ?? '',
      probability: (json['probability'] as num).toDouble(),
      riskLevel: json['risk_level'] ?? 'moderate',
      recommendation: json['recommendation'] ?? '',
      llmRecommendation: json['llm_recommendation'] ?? json['recommendation'] ?? '',
      selectedFeatures: (json['selected_features'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      inferenceLatencyMs: (json['inference_latency_ms'] as num?)?.toDouble() ?? 0,
      latencyMs: (json['latency_ms'] as num).toDouble(),
      modelUsed: json['model_used'] ?? 'classical_fp32',
    );
  }

  /// Convert riskLevel to a human-readable label
  String get riskLabel {
    switch (riskLevel) {
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

  /// Confidence % to display (1 - probability for low risk feels more natural)
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
      classicalFp32: json['classical_fp32'] ?? false,
      classicalInt8: json['classical_int8'] ?? false,
      hybridFp32: json['hybrid_fp32'] ?? false,
      hybridInt8: json['hybrid_int8'] ?? false,
      selectedFeatures: (json['selected_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modelDir: json['model_dir'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class NeuralVoiceApi {
  static final NeuralVoiceApi _instance = NeuralVoiceApi._internal();
  factory NeuralVoiceApi() => _instance;
  NeuralVoiceApi._internal();

  final String _base = ApiConfig.baseUrl;

  // ---- Health check -------------------------------------------------------

  Future<bool> isHealthy() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/api/v1/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Models status ------------------------------------------------------

  Future<ModelsStatus?> getModelsStatus() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/api/v1/models'))
          .timeout(ApiConfig.timeout);
      if (resp.statusCode == 200) {
        return ModelsStatus.fromJson(jsonDecode(resp.body));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // ---- Predict from audio file --------------------------------------------

  Future<PredictionResult> predictFromAudio(
    String filePath, {
    String modelVariant = 'classical_fp32',
    bool useLlm = true,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Audio file not found: $filePath');
    }

    final uri = Uri.parse('$_base/api/v1/predict').replace(queryParameters: {
      'model_variant': modelVariant,
      'use_llm': useLlm.toString(),
    });

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: 'voice_sample.wav',
      ),
    );

    final streamedResponse =
        await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return PredictionResult.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
        'API error ${response.statusCode}: ${body['detail'] ?? 'Unknown error'}',
      );
    }
  }
}
