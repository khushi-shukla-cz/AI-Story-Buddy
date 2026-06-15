import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/quiz_card.dart';
import '../widgets/story_card.dart';

/// The single screen of the Peblo Smart Story Buddy app.
///
/// Composition:
/// - AI Buddy (Lottie) with auto-changing emotional state
/// - Story card with "Read Story" CTA and narration progress
/// - Dynamically rendered quiz, revealed after narration completes
/// - Confetti + success banner on correct answer
class StoryBuddyScreen extends ConsumerStatefulWidget {
  const StoryBuddyScreen({super.key});

  @override
  ConsumerState<StoryBuddyScreen> createState() => _StoryBuddyScreenState();
}

class _StoryBuddyScreenState extends ConsumerState<StoryBuddyScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyProvider);
    final quizState = ref.watch(quizProvider);

    debugPrint(
        '[StoryBuddyScreen] build() — narrationStatus=${storyState.narrationStatus}, '
        'buddyState=${storyState.buddyState}, quizRevealed=${storyState.quizRevealed}, '
        'quizCompleted=${quizState.isCompleted}');

    // Fire confetti exactly once when the quiz becomes completed.
    ref.listen(quizProvider, (previous, next) {
      final justCompleted =
          (previous?.isCompleted ?? false) == false && next.isCompleted;
      if (justCompleted) {
        debugPrint('[StoryBuddyScreen] quiz completed -> playing confetti');
        _confettiController.play();
      }
    });

    // Trace quizRevealed transitions specifically.
    ref.listen(storyProvider, (previous, next) {
      if ((previous?.quizRevealed ?? false) != next.quizRevealed) {
        debugPrint(
            '[StoryBuddyScreen] quizRevealed changed: ${previous?.quizRevealed} -> ${next.quizRevealed}');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(buddyState: storyState.buddyState),
                    const SizedBox(height: 20),

                    StoryCard(
                      story: storyState.story,
                      narrationStatus: storyState.narrationStatus,
                    ),
                    const SizedBox(height: 16),

                    // TTS error feedback.
                    AnimatedSwitcher(
                      duration: AppConstants.shortAnim,
                      child: storyState.narrationStatus ==
                              NarrationStatus.error
                          ? _ErrorRetryBanner(
                              key: const ValueKey('tts-error'),
                              message: storyState.errorMessage ??
                                  AppConstants.ttsErrorMessage,
                              onRetry: () => ref
                                  .read(storyProvider.notifier)
                                  .retryReadStory(),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-error')),
                    ),

                    const SizedBox(height: 16),

                    // Read Story button — hidden once quiz is revealed
                    // to keep focus on the activity, per the "Initial
                    // State -> Reveal Quiz" flow.
                    AnimatedSwitcher(
                      duration: AppConstants.mediumAnim,
                      child: storyState.quizRevealed
                          ? const SizedBox.shrink(key: ValueKey('no-button'))
                          : _ReadStoryButton(
                              key: const ValueKey('read-button'),
                              isNarrating: storyState.isNarrating,
                              onPressed: () =>
                                  ref.read(storyProvider.notifier).readStory(),
                            ),
                    ),

                    // Quiz reveal with fade + slide transition.
                    AnimatedSwitcher(
                      duration: AppConstants.longAnim,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOutCubic),
                          ),
                          child: child,
                        ),
                      ),
                      child: !storyState.quizRevealed
                          ? const SizedBox.shrink(key: ValueKey('no-quiz'))
                          : Padding(
                              key: const ValueKey('quiz'),
                              padding: const EdgeInsets.only(top: 8),
                              child: _QuizSection(
                                loadError: quizState.loadError,
                                quiz: quizState.quiz,
                                onRetryLoad: () =>
                                    ref.read(quizProvider.notifier).retryLoad(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Confetti overlay, anchored to top-center, falling down.
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 18,
                minBlastForce: 8,
                emissionFrequency: 0.08,
                numberOfParticles: 24,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.accentYellow,
                  AppTheme.accentGreen,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top header with app title and the AI Buddy.
class _Header extends StatelessWidget {
  final BuddyState buddyState;

  const _Header({required this.buddyState});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peblo Story Buddy',
                style: GoogleFonts.baloo2(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Listen, learn, and play! 🌟',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BuddyWidget(buddyState: buddyState, size: 96),
      ],
    );
  }
}

/// Primary CTA button to start narration.
class _ReadStoryButton extends StatelessWidget {
  final bool isNarrating;
  final VoidCallback onPressed;

  const _ReadStoryButton({
    super.key,
    required this.isNarrating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.primaryButtonGradient,
        boxShadow: AppTheme.softShadow,
      ),
      child: ElevatedButton(
        onPressed: isNarrating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withOpacity(0.85),
        ),
        child: isNarrating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Pip is reading...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Read Story'),
                ],
              ),
      ),
    ).animate().fadeIn(duration: AppConstants.shortAnim);
  }
}

/// Friendly error banner with retry, used for TTS failures.
class _ErrorRetryBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetryBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('😟', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppConstants.shortAnim).shake(hz: 4);
  }
}

/// Wraps quiz loading errors and the actual [QuizCard].
class _QuizSection extends StatelessWidget {
  final String? loadError;
  final QuizModel? quiz;
  final VoidCallback onRetryLoad;

  const _QuizSection({
    required this.loadError,
    required this.quiz,
    required this.onRetryLoad,
  });

  @override
  Widget build(BuildContext context) {
    if (loadError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loadError!,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetryLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (quiz == null) {
      // Defensive fallback — should not normally be reached because
      // _loadQuiz runs synchronously on provider creation.
      return const SizedBox.shrink();
    }

    return QuizCard(quiz: quiz!);
  }
}