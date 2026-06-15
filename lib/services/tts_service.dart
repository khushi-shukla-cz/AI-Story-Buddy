import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Possible states of the narration lifecycle.
enum TtsPlaybackState { idle, loading, playing, completed, error }

/// Wraps [FlutterTts] with defensive error handling so narration
/// failures never crash or freeze the UI.
///
/// CRITICAL FIX: `awaitSpeakCompletion(true)` must be set on Android
/// (and iOS) for `_flutterTts.speak()` to resolve only once narration
/// has actually finished. Without it, `speak()` resolves as soon as the
/// utterance is *queued* by the platform engine, and the completion
/// handler is unreliable on many Android versions/OEM TTS engines
/// (Samsung, MIUI, etc.). This caused [TtsPlaybackState.completed] to
/// never be emitted, which left `quizRevealed` stuck at `false`.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initializes the TTS engine and configures sane defaults for
  /// child-friendly narration. Safe to call multiple times.
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('[TtsService] initialize() skipped — already initialized');
      return true;
    }
    try {
      debugPrint('[TtsService] initialize() starting...');

      // CRITICAL: makes speak() resolve only when narration truly ends.
      await _flutterTts.awaitSpeakCompletion(true);

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.42); // slightly slower for kids
      await _flutterTts.setPitch(1.05);
      await _flutterTts.setVolume(1.0);

      _isInitialized = true;
      debugPrint('[TtsService] initialize() success');
      return true;
    } catch (e, st) {
      _isInitialized = false;
      debugPrint('[TtsService] initialize() FAILED: $e');
      debugPrint('$st');
      return false;
    }
  }

  /// Speaks the given [text]. Returns a stream of [TtsPlaybackState]
  /// updates so the UI can react (loading -> playing -> completed/error).
  ///
  /// With `awaitSpeakCompletion(true)`, `_flutterTts.speak()` itself
  /// will not return until the platform reports completion (or error).
  /// The completion/error/cancel handlers are kept as a defensive
  /// secondary signal in case a platform fires them instead of (or in
  /// addition to) resolving the `speak()` future.
  Stream<TtsPlaybackState> speak(String text) {
    final controller = StreamController<TtsPlaybackState>();
    var terminalEmitted = false;

    void emitTerminal(TtsPlaybackState state) {
      if (terminalEmitted || controller.isClosed) return;
      terminalEmitted = true;
      debugPrint('[TtsService] emitting terminal state: $state');
      controller.add(state);
      controller.close();
    }

    () async {
      debugPrint('[TtsService] speak() called. text length=${text.length}');
      controller.add(TtsPlaybackState.loading);

      final ready = _isInitialized ? true : await initialize();
      if (!ready) {
        debugPrint('[TtsService] speak() aborted — initialize() failed');
        emitTerminal(TtsPlaybackState.error);
        return;
      }

      try {
        // Defensive secondary signals — may fire on some platforms
        // either alongside or instead of the speak() future resolving.
        _flutterTts.setCompletionHandler(() {
          debugPrint('[TtsService] setCompletionHandler fired');
          emitTerminal(TtsPlaybackState.completed);
        });

        _flutterTts.setErrorHandler((msg) {
          debugPrint('[TtsService] setErrorHandler fired: $msg');
          emitTerminal(TtsPlaybackState.error);
        });

        _flutterTts.setCancelHandler(() {
          debugPrint('[TtsService] setCancelHandler fired');
          emitTerminal(TtsPlaybackState.completed);
        });

        debugPrint('[TtsService] calling _flutterTts.speak()...');
        controller.add(TtsPlaybackState.playing);

        // With awaitSpeakCompletion(true), this await blocks until
        // narration finishes (or errors), making this the primary
        // completion signal.
        final result = await _flutterTts.speak(text);
        debugPrint('[TtsService] _flutterTts.speak() resolved with result=$result');

        if (result == 1) {
          emitTerminal(TtsPlaybackState.completed);
        } else {
          emitTerminal(TtsPlaybackState.error);
        }
      } catch (e, st) {
        debugPrint('[TtsService] speak() threw: $e');
        debugPrint('$st');
        emitTerminal(TtsPlaybackState.error);
      }
    }();

    return controller.stream;
  }

  /// Stops any ongoing narration. Never throws.
  Future<void> stop() async {
    try {
      debugPrint('[TtsService] stop() called');
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[TtsService] stop() error (ignored): $e');
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}