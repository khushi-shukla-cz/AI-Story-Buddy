import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Represents one saved quiz attempt record, used as a lightweight
/// foundation for future personalized-learning features.
class LearnerProgressRecord {
  final String questionId;
  final int attempts;
  final String correctAnswer;
  final DateTime timestamp;

  const LearnerProgressRecord({
    required this.questionId,
    required this.attempts,
    required this.correctAnswer,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'attempts': attempts,
        'correctAnswer': correctAnswer,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LearnerProgressRecord.fromJson(Map<String, dynamic> json) {
    return LearnerProgressRecord(
      questionId: json['questionId'] as String? ?? 'unknown',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correctAnswer: json['correctAnswer'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Handles persistence of learner progress using [SharedPreferences].
/// All methods are defensive: storage failures never throw past this
/// layer — they resolve to `false`/empty results instead.
class StorageService {
  /// Saves a completed quiz attempt record. Appends to any existing
  /// history stored under [AppConstants.prefsKeyProgress].
  Future<bool> saveProgress(LearnerProgressRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadProgress();
      existing.add(record);

      final encoded = jsonEncode(
        existing.map((r) => r.toJson()).toList(),
      );

      return await prefs.setString(AppConstants.prefsKeyProgress, encoded);
    } catch (_) {
      return false;
    }
  }

  /// Loads all stored progress records. Returns an empty list on any
  /// error (missing key, corrupt JSON, etc.) rather than throwing.
  Future<List<LearnerProgressRecord>> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefsKeyProgress);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LearnerProgressRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Clears all stored progress. Returns true on success.
  Future<bool> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(AppConstants.prefsKeyProgress);
    } catch (_) {
      return false;
    }
  }
}
