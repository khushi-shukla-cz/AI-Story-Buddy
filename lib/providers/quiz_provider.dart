import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/quiz_model.dart';
import '../services/storage_service.dart';
import 'story_provider.dart';

/// Outcome of the most recent answer selection, used to drive
/// shake/celebration animations without re-deriving from raw state.
enum AnswerFeedback { none, correct, incorrect }

/// Immutable state for the quiz engine.
class QuizState {
  /// The loaded quiz, or null if loading/error.
  final QuizModel? quiz;

  /// Null if quiz JSON failed to load/parse.
  final String? loadError;

  /// The option the learner most recently selected (for highlighting).
  final String? selectedOption;

  /// Number of attempts made on the current question (starts at 0).
  final int attempts;

  /// Whether the learner has answered correctly and the quiz is locked.
  final bool isCompleted;

  /// Current adaptive hint message to display (if any).
  final String? hintMessage;

  /// Drives one-shot feedback animations (shake / confetti).
  final AnswerFeedback feedback;

  /// Whether progress has been persisted for this completion.
  final bool progressSaved;

  const QuizState({
    this.quiz,
    this.loadError,
    this.selectedOption,
    this.attempts = 0,
    this.isCompleted = false,
    this.hintMessage,
    this.feedback = AnswerFeedback.none,
    this.progressSaved = false,
  });

  QuizState copyWith({
    QuizModel? quiz,
    String? loadError,
    String? selectedOption,
    int? attempts,
    bool? isCompleted,
    String? hintMessage,
    AnswerFeedback? feedback,
    bool? progressSaved,
    bool clearHint = false,
    bool clearLoadError = false,
  }) {
    return QuizState(
      quiz: quiz ?? this.quiz,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      selectedOption: selectedOption ?? this.selectedOption,
      attempts: attempts ?? this.attempts,
      isCompleted: isCompleted ?? this.isCompleted,
      hintMessage: clearHint ? null : (hintMessage ?? this.hintMessage),
      feedback: feedback ?? this.feedback,
      progressSaved: progressSaved ?? this.progressSaved,
    );
  }
}

/// Provides the singleton [StorageService] instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Manages quiz loading, answer evaluation, the adaptive hint engine,
/// and persistence of learner progress.
class QuizNotifier extends StateNotifier<QuizState> {
  final StorageService _storageService;
  final Ref _ref;

  QuizNotifier(this._storageService, this._ref) : super(const QuizState()) {
    _loadQuiz();
  }

  /// Loads the quiz from the local mock-backend JSON string.
  /// Handles missing/corrupt data gracefully.
  void _loadQuiz() {
    try {
      final decoded = jsonDecode(AppConstants.quizJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Quiz JSON root must be an object.');
      }
      final quiz = QuizModel.fromJson(decoded);
      state = state.copyWith(quiz: quiz, clearLoadError: true);
    } catch (e) {
      state = state.copyWith(
        loadError:
            "Hmm, the quiz couldn't load right now. Please try again later.",
      );
    }
  }

  /// Allows retrying quiz load (e.g. after a transient error).
  void retryLoad() => _loadQuiz();

  /// Evaluates the learner's selected [option] against the correct
  /// answer, updating attempts, hints, buddy state, and persistence.
  Future<void> selectAnswer(String option) async {
    final quiz = state.quiz;
    if (quiz == null || state.isCompleted) return;

    final isCorrect = option == quiz.answer;
    final newAttempts = state.attempts + 1;

    if (isCorrect) {
      state = state.copyWith(
        selectedOption: option,
        attempts: newAttempts,
        isCompleted: true,
        feedback: AnswerFeedback.correct,
        clearHint: true,
      );

      _ref.read(storyProvider.notifier).setBuddyCelebrating();
      await _persistProgress(quiz, newAttempts);
    } else {
      final hint = _hintForAttempt(newAttempts, quiz.hint);

      state = state.copyWith(
        selectedOption: option,
        attempts: newAttempts,
        feedback: AnswerFeedback.incorrect,
        hintMessage: hint,
      );

      _ref.read(storyProvider.notifier).setBuddyEncouraging();
    }
  }

  /// Adaptive hint engine: escalates guidance based on attempt count.
  String _hintForAttempt(int attemptNumber, String revealHint) {
    switch (attemptNumber) {
      case 1:
        return AppConstants.hintAttempt1;
      case 2:
        return AppConstants.hintAttempt2;
      default:
        return revealHint;
    }
  }

  /// Called by the UI after the shake/incorrect animation finishes, to
  /// reset the one-shot feedback flag and return the buddy to thinking.
  void acknowledgeFeedback() {
    if (state.feedback == AnswerFeedback.incorrect) {
      state = state.copyWith(
        feedback: AnswerFeedback.none,
        selectedOption: null,
      );
      _ref.read(storyProvider.notifier).setBuddyThinking();
    } else if (state.feedback == AnswerFeedback.correct) {
      state = state.copyWith(feedback: AnswerFeedback.none);
    }
  }

  Future<void> _persistProgress(QuizModel quiz, int attempts) async {
    final record = LearnerProgressRecord(
      questionId: quiz.questionId,
      attempts: attempts,
      correctAnswer: quiz.answer,
      timestamp: DateTime.now(),
    );

    final saved = await _storageService.saveProgress(record);
    state = state.copyWith(progressSaved: saved);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return QuizNotifier(storage, ref);
});
