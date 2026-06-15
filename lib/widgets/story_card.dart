import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/story_model.dart';
import '../providers/story_provider.dart';

/// Displays the story title, body text, and an inline narration
/// progress indicator while the story is being read aloud.
class StoryCard extends StatelessWidget {
  final StoryModel story;
  final NarrationStatus narrationStatus;

  const StoryCard({
    super.key,
    required this.story,
    required this.narrationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrating = narrationStatus == NarrationStatus.loading ||
        narrationStatus == NarrationStatus.playing;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: isNarrating
                ? AppTheme.secondary.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    story.title,
                    style: GoogleFonts.baloo2(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              story.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            AnimatedSwitcher(
              duration: AppConstants.shortAnim,
              child: isNarrating
                  ? const Padding(
                      key: ValueKey('narration-bar'),
                      padding: EdgeInsets.only(top: 16),
                      child: _NarrationProgressBar(),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-bar')),
            ),
          ],
        ),
      ),
    );
  }
}

/// A friendly animated progress bar shown while narration is active.
class _NarrationProgressBar extends StatelessWidget {
  const _NarrationProgressBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.background,
                valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text('🔊', style: TextStyle(fontSize: 18))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.15, duration: 600.ms),
      ],
    );
  }
}
