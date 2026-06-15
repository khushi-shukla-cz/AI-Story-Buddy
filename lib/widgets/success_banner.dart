import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Celebratory banner shown when the learner answers correctly.
/// Displays the success message and the total attempts used.
class SuccessBanner extends StatelessWidget {
  final int attempts;

  const SuccessBanner({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    final attemptsLabel = attempts == 1 ? 'attempt' : 'attempts';

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        decoration: BoxDecoration(
          gradient: AppTheme.successGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConstants.successTitle,
                    style: GoogleFonts.baloo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.successSubtitle,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Solved in $attempts $attemptsLabel ⭐',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: AppConstants.mediumAnim)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic)
          .scaleXY(begin: 0.96, end: 1, curve: Curves.easeOutBack),
    );
  }
}
