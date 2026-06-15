import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/story_model.dart';
import '../services/tts_service.dart';

/// The Peblo AI Buddy's visual/emotional state.
enum BuddyState { idle, reading, thinking, encouraging, celebrating }

/// Narration / audio playback state.
enum NarrationStatus { idle, loading, playing, completed, error }

/// Immutable state describing the story + narration + buddy.
class StoryState {
  final StoryModel story;
  final NarrationStatus narrationStatus;
  final BuddyState buddyState;
  final bool quizRevealed;
  final String? errorMessage;

  const StoryState({
    required this.story,
    this.narrationStatus = NarrationStatus.idle,
    this.buddyState = BuddyState.idle,
    this.quizRevealed = false,
    this.errorMessage,
  });

  StoryState copyWith({
    StoryModel? story,
    NarrationStatus? narrationStatus,
    BuddyState? buddyState,
    bool? quizRevealed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoryState(
      story: story ?? this.story,
      narrationStatus: narrationStatus ?? this.narrationStatus,
      buddyState: buddyState ?? this.buddyState,
      quizRevealed: quizRevealed ?? this.quizRevealed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// True while narration is actively loading or playing — used to
  /// disable the "Read Story" button.
  bool get isNarrating =>
      narrationStatus == NarrationStatus.loading ||
      narrationStatus == NarrationStatus.playing;
}

/// Provides the singleton [TtsService] instance.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Manages story content, narration lifecycle, and the buddy's
/// emotional state. The buddy state automatically reflects narration
/// and quiz progress per the product spec.
class StoryNotifier extends StateNotifier<StoryState> {
  final TtsService _ttsService;

  StoryNotifier(this._ttsService)
      : super(
          const StoryState(
            story: StoryModel(
              title: AppConstants.storyTitle,
              text: AppConstants.storyText,
            ),
          ),
        );

  /// Begins narration of the story. Updates [BuddyState] to
  /// [BuddyState.reading] while playing, handles errors gracefully,
  /// and reveals the quiz with a transition once narration completes.
  Future<void> readStory() async {
  if (state.isNarrating) {
    debugPrint('[StoryNotifier] readStory() ignored — already narrating');
    return;
  }

  debugPrint('[StoryNotifier] readStory() starting');

  state = state.copyWith(
    narrationStatus: NarrationStatus.loading,
    buddyState: BuddyState.reading,
    clearError: true,
  );

  debugPrint(
    '[StoryNotifier] state -> narrationStatus=${state.narrationStatus}, '
    'buddyState=${state.buddyState}, quizRevealed=${state.quizRevealed}',
  );

  final stream = _ttsService.speak(state.story.text);

  await for (final status in stream) {
    debugPrint('[StoryNotifier] received status: $status');

    switch (status) {
      case TtsPlaybackState.idle:
        state = state.copyWith(
          narrationStatus: NarrationStatus.idle,
        );
        break;

      case TtsPlaybackState.loading:
        state = state.copyWith(
          narrationStatus: NarrationStatus.loading,
        );
        break;

      case TtsPlaybackState.playing:
        state = state.copyWith(
          narrationStatus: NarrationStatus.playing,
          buddyState: BuddyState.reading,
        );
        break;

      case TtsPlaybackState.completed:
        debugPrint('QUIZ REVEAL TRIGGERED');

        state = state.copyWith(
          narrationStatus: NarrationStatus.completed,
          buddyState: BuddyState.thinking,
          quizRevealed: true,
        );

        debugPrint(
          'quizRevealed = ${state.quizRevealed}',
        );
        break;

      case TtsPlaybackState.error:
        state = state.copyWith(
          narrationStatus: NarrationStatus.error,
          buddyState: BuddyState.idle,
          errorMessage: AppConstants.ttsErrorMessage,
        );
        break;
    }

    debugPrint(
      '[StoryNotifier] state -> narrationStatus=${state.narrationStatus}, '
      'buddyState=${state.buddyState}, quizRevealed=${state.quizRevealed}',
    );
  }

  debugPrint('[StoryNotifier] readStory() stream closed');
}

  /// Allows the user to retry narration after an error.
  Future<void> retryReadStory() async {
    state = state.copyWith(clearError: true);
    await readStory();
  }

  /// Called by the quiz flow when the user answers incorrectly.
  void setBuddyEncouraging() {
    state = state.copyWith(buddyState: BuddyState.encouraging);
  }

  /// Called by the quiz flow when the user answers correctly.
  void setBuddyCelebrating() {
    state = state.copyWith(buddyState: BuddyState.celebrating);
  }

  /// Returns the buddy to a thinking state (e.g. after an encouraging
  /// nudge, while the learner is still attempting the quiz).
  void setBuddyThinking() {
    state = state.copyWith(buddyState: BuddyState.thinking);
  }
}

final storyProvider = StateNotifierProvider<StoryNotifier, StoryState>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  return StoryNotifier(tts);
});