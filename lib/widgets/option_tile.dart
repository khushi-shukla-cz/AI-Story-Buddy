import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Visual state of a single quiz option tile.
enum OptionTileState { neutral, selectedCorrect, selectedWrong, disabled }

/// A single tappable quiz option. Built generically so it works for
/// any number of options (3, 4, 5+) without code changes.
class OptionTile extends StatelessWidget {
  final String label;
  final OptionTileState tileState;
  final bool shake;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.label,
    required this.tileState,
    required this.shake,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (tileState) {
      case OptionTileState.selectedCorrect:
        return AppTheme.accentGreen.withOpacity(0.15);
      case OptionTileState.selectedWrong:
        return AppTheme.accentRed.withOpacity(0.12);
      case OptionTileState.neutral:
      case OptionTileState.disabled:
        return AppTheme.cardWhite;
    }
  }

  Color get _borderColor {
    switch (tileState) {
      case OptionTileState.selectedCorrect:
        return AppTheme.accentGreen;
      case OptionTileState.selectedWrong:
        return AppTheme.accentRed;
      case OptionTileState.neutral:
      case OptionTileState.disabled:
        return AppTheme.background;
    }
  }

  Widget? get _trailingIcon {
    switch (tileState) {
      case OptionTileState.selectedCorrect:
        return const Icon(Icons.check_circle_rounded,
            color: AppTheme.accentGreen, size: 26);
      case OptionTileState.selectedWrong:
        return const Icon(Icons.cancel_rounded,
            color: AppTheme.accentRed, size: 26);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        tileState == OptionTileState.disabled || onTap == null;

    Widget content = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppTheme.primary.withOpacity(0.08),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor, width: 2),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDisabled && tileState == OptionTileState.disabled
                        ? AppTheme.textMuted
                        : AppTheme.textDark,
                  ),
                ),
              ),
              if (_trailingIcon != null) _trailingIcon!,
            ],
          ),
        ),
      ),
    );

    content = content
        .animate(target: 1)
        .scaleXY(begin: 0.98, end: 1, duration: 180.ms, curve: Curves.easeOut);

    if (shake) {
      content = content
          .animate()
          .shake(hz: 6, curve: Curves.easeInOut, duration: 420.ms);
    }

    return content;
  }
}
