import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/story_provider.dart';

/// Renders the Peblo AI Buddy as a Lottie animation whose source file
/// changes automatically based on [BuddyState]. Includes a subtle
/// floating idle animation for extra charm.
///
/// If a Lottie asset is missing (e.g. not bundled in this environment),
/// a friendly emoji-based fallback is shown instead so the app never
/// crashes due to missing assets.
class BuddyWidget extends StatelessWidget {
  final BuddyState buddyState;
  final double size;

  const BuddyWidget({
    super.key,
    required this.buddyState,
    this.size = 140,
  });

  String get _assetPath {
    switch (buddyState) {
      case BuddyState.idle:
        return AppConstants.lottieIdle;
      case BuddyState.reading:
        return AppConstants.lottieReading;
      case BuddyState.thinking:
        return AppConstants.lottieThinking;
      case BuddyState.encouraging:
        return AppConstants.lottieEncouraging;
      case BuddyState.celebrating:
        return AppConstants.lottieCelebrating;
    }
  }

  String get _fallbackEmoji {
    switch (buddyState) {
      case BuddyState.idle:
        return '🤖';
      case BuddyState.reading:
        return '📖';
      case BuddyState.thinking:
        return '🤔';
      case BuddyState.encouraging:
        return '💪';
      case BuddyState.celebrating:
        return '🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: AppConstants.mediumAnim,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Container(
          key: ValueKey(buddyState),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardWhite,
            boxShadow: AppTheme.softShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: ClipOval(
            child: Lottie.asset(
              _assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    _fallbackEmoji,
                    style: TextStyle(fontSize: size * 0.45),
                  ),
                );
              },
            ),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            .moveY(
              begin: 0,
              end: buddyState == BuddyState.idle ? -10 : -4,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
