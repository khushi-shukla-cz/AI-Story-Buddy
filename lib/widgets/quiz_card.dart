import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import 'option_tile.dart';
import 'success_banner.dart';

/// Renders the dynamic quiz UI from a [QuizModel]: question, options
/// (via ListView.builder so any option count works), adaptive hints,
/// wrong-answer shake/haptics, and the success state.
class QuizCard extends ConsumerStatefulWidget {
  final QuizModel quiz;

  const QuizCard({super.key, required this.quiz});

  @override
  ConsumerState<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends ConsumerState<QuizCard> {
  // Tracks whether a feedback-acknowledgment callback has already been
  // scheduled for the CURRENT feedback event, so that rebuilds during
  // the 450ms shake window don't stack duplicate haptics/callbacks.
  bool _feedbackHandled = false;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    debugPrint(
        '[QuizCard] build() — attempts=${quizState.attempts}, '
        'isCompleted=${quizState.isCompleted}, feedback=${quizState.feedback}, '
        'hint=${quizState.hintMessage}');

    // Trigger haptic feedback + auto-clear the shake animation as a
    // side effect of an incorrect/correct answer, without blocking
    // build. Guarded by _feedbackHandled so repeated rebuilds while
    // feedback is still "incorrect"/"correct" don't reschedule.
    if (quizState.feedback == AnswerFeedback.incorrect) {
      if (!_feedbackHandled) {
        _feedbackHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 450));
          if (mounted) {
            ref.read(quizProvider.notifier).acknowledgeFeedback();
            _feedbackHandled = false;
          }
        });
      }
    } else if (quizState.feedback == AnswerFeedback.correct) {
      if (!_feedbackHandled) {
        _feedbackHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          HapticFeedback.lightImpact();
          ref.read(quizProvider.notifier).acknowledgeFeedback();
          _feedbackHandled = false;
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('❓', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.quiz.question,
                        style: GoogleFonts.baloo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dynamically built options — works for 3, 4, 5+ items.
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.quiz.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.quiz.options[index];
                    final tileState = _resolveTileState(
                      option: option,
                      quizState: quizState,
                    );
                    final shouldShake = quizState.feedback ==
                            AnswerFeedback.incorrect &&
                        quizState.selectedOption == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OptionTile(
                        label: option,
                        tileState: tileState,
                        shake: shouldShake,
                        onTap: quizState.isCompleted
                            ? null
                            : () => ref
                                .read(quizProvider.notifier)
                                .selectAnswer(option),
                      ),
                    );
                  },
                ),

                // Adaptive hint message.
                AnimatedSwitcher(
                  duration: AppConstants.shortAnim,
                  child: quizState.hintMessage != null &&
                          !quizState.isCompleted
                      ? _HintBubble(
                          key: ValueKey(quizState.hintMessage),
                          message: quizState.hintMessage!,
                        )
                      : const SizedBox.shrink(key: ValueKey('no-hint')),
                ),
              ],
            ),
          ),
        ),

        // Success banner appears below the quiz once completed.
        AnimatedSwitcher(
          duration: AppConstants.mediumAnim,
          child: quizState.isCompleted
              ? Padding(
                  key: const ValueKey('success'),
                  padding: const EdgeInsets.only(top: 16),
                  child: SuccessBanner(attempts: quizState.attempts),
                )
              : const SizedBox.shrink(key: ValueKey('no-success')),
        ),
      ],
    );
  }

  OptionTileState _resolveTileState({
    required String option,
    required QuizState quizState,
  }) {
    final quiz = widget.quiz;

    if (quizState.isCompleted) {
      if (option == quiz.answer) return OptionTileState.selectedCorrect;
      return OptionTileState.disabled;
    }

    if (quizState.selectedOption == option &&
        quizState.feedback == AnswerFeedback.incorrect) {
      return OptionTileState.selectedWrong;
    }

    return OptionTileState.neutral;
  }
}

/// Small speech-bubble-style hint shown by the adaptive hint engine.
class _HintBubble extends StatelessWidget {
  final String message;

  const _HintBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentYellow.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppConstants.shortAnim)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}