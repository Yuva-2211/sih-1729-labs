import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------------
// ReportRecord — a DB row
// ---------------------------------------------------------------------------

class ReportRecord {
  final int? id;
  final String requestId;
  final DateTime timestamp;
  final String riskLevel;
  final double probability;
  final String llmRecommendation;
  final String recommendation;
  final String modelUsed;
  final String selectedFeaturesJson; // JSON-encoded Map<String,double>
  final String? audioPath;
  final double latencyMs;
  final double inferenceLatencyMs;
  final String patientName;

  ReportRecord({
    this.id,
    required this.requestId,
    required this.timestamp,
    required this.riskLevel,
    required this.probability,
    required this.llmRecommendation,
    required this.recommendation,
    required this.modelUsed,
    required this.selectedFeaturesJson,
    this.audioPath,
    required this.latencyMs,
    required this.inferenceLatencyMs,
    this.patientName = 'Participant',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'request_id': requestId,
        'timestamp': timestamp.toIso8601String(),
        'risk_level': riskLevel,
        'probability': probability,
        'llm_recommendation': llmRecommendation,
        'recommendation': recommendation,
        'model_used': modelUsed,
        'selected_features_json': selectedFeaturesJson,
        'audio_path': audioPath,
        'latency_ms': latencyMs,
        'inference_latency_ms': inferenceLatencyMs,
        'patient_name': patientName,
      };

  factory ReportRecord.fromMap(Map<String, dynamic> m) => ReportRecord(
        id: m['id'] as int?,
        requestId: m['request_id'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        riskLevel: m['risk_level'] as String,
        probability: (m['probability'] as num).toDouble(),
        llmRecommendation: m['llm_recommendation'] as String? ?? '',
        recommendation: m['recommendation'] as String? ?? '',
        modelUsed: m['model_used'] as String? ?? 'classical_fp32',
        selectedFeaturesJson: m['selected_features_json'] as String? ?? '{}',
        audioPath: m['audio_path'] as String?,
        latencyMs: (m['latency_ms'] as num?)?.toDouble() ?? 0.0,
        inferenceLatencyMs: (m['inference_latency_ms'] as num?)?.toDouble() ?? 0.0,
        patientName: m['patient_name'] as String? ?? 'Participant',
      );

  /// Convenience: decode selectedFeatures back to Map
  Map<String, double> get selectedFeatures {
    try {
      final raw = jsonDecode(selectedFeaturesJson) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// Human-readable risk label
  String get riskLabel {
    switch (riskLevel.toLowerCase()) {
      case 'low': return 'Low likelihood';
      case 'moderate': return 'Moderate likelihood';
      case 'high': return 'High likelihood';
      default: return 'Moderate likelihood';
    }
  }

  double get confidencePercent => probability * 100;

  /// Build a lightweight PredictionResult from this record (no waveform data)
  PredictionResult toPredictionResult() => PredictionResult(
        requestId: requestId,
        probability: probability,
        riskLevel: riskLevel,
        recommendation: recommendation,
        llmRecommendation: llmRecommendation,
        selectedFeatures: selectedFeatures,
        inferenceLatencyMs: inferenceLatencyMs,
        latencyMs: latencyMs,
        modelUsed: modelUsed,
        rawWaveform: const [],
        preprocessedWaveform: const [],
        patientName: patientName,
      );
}

// ---------------------------------------------------------------------------
// ReportDatabase — singleton SQLite service
// ---------------------------------------------------------------------------

class ReportDatabase {
  static final ReportDatabase _instance = ReportDatabase._internal();
  factory ReportDatabase() => _instance;
  ReportDatabase._internal();

  static Database? _db;

  static const _dbName = 'neurovoice_reports.db';
  static const _dbVersion = 2;
  static const _table = 'reports';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id                    INTEGER PRIMARY KEY AUTOINCREMENT,
            request_id            TEXT NOT NULL,
            timestamp             TEXT NOT NULL,
            risk_level            TEXT NOT NULL,
            probability           REAL NOT NULL,
            llm_recommendation    TEXT,
            recommendation        TEXT,
            model_used            TEXT,
            selected_features_json TEXT,
            audio_path            TEXT,
            latency_ms            REAL,
            inference_latency_ms  REAL,
            patient_name          TEXT DEFAULT 'Participant'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE $_table ADD COLUMN patient_name TEXT DEFAULT 'Participant'");
          } catch (_) {}
        }
      },
    );
  }

  // ---- CRUD ---------------------------------------------------------------

  /// Save a PredictionResult to the DB. Returns the inserted row id.
  Future<int> saveReport(PredictionResult result, {String? audioPath}) async {
    final db = await database;
    final record = ReportRecord(
      requestId: result.requestId,
      timestamp: DateTime.now(),
      riskLevel: result.riskLevel,
      probability: result.probability,
      llmRecommendation: result.llmRecommendation,
      recommendation: result.recommendation,
      modelUsed: result.modelUsed,
      selectedFeaturesJson: jsonEncode(result.selectedFeatures),
      audioPath: audioPath,
      latencyMs: result.latencyMs,
      inferenceLatencyMs: result.inferenceLatencyMs,
      patientName: result.patientName,
    );
    return db.insert(_table, record.toMap());
  }

  /// Retrieve all reports ordered by newest first.
  Future<List<ReportRecord>> getAllReports() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'timestamp DESC');
    return maps.map(ReportRecord.fromMap).toList();
  }

  /// Retrieve a single report by its row id.
  Future<ReportRecord?> getReportById(int id) async {
    final db = await database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : ReportRecord.fromMap(maps.first);
  }

  /// Delete a report by its row id.
  Future<void> deleteReport(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all records (for testing / reset).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }

  /// Total number of saved reports.
  Future<int> countReports() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return result.first['cnt'] as int;
  }
}
