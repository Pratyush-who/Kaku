import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../constants/app_constants.dart';

/// Screen footer brand element following Rule 14 (Screen Ending & Visual Polish).
/// Ensures screens conclude with intentional brand polish rather than an abrupt cutoff.
class ScreenFooterBrand extends StatelessWidget {
  const ScreenFooterBrand({
    super.key,
    this.tagline = AppConstants.footerNotice,
    this.showDivider = true,
  });

  final String tagline;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDivider) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1.0,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.darkBorder,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1.0,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.darkBorder,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
          ],
          Text(
            tagline.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.brandTagline.copyWith(
              fontSize: 10.0,
              letterSpacing: 2.2,
              color: AppColors.textTertiaryDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            AppConstants.appVersion,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9.5,
              color: AppColors.textDisabledDark,
            ),
          ),
        ],
      ),
    );
  }
}
