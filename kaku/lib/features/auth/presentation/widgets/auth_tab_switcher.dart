import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/auth_state.dart';

/// Smooth sliding pill tab switcher for toggling between Sign In and Sign Up (Rule 24 & 29).
/// Enforces organic pill geometry instead of boxy buttons ("dont use a square for details").
class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  final AuthMode currentMode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSignIn = currentMode == AuthMode.signIn;

    return Container(
      height: 48.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth) / 2;

          return Stack(
            children: [
              // Sliding Animated Pill Indicator
              AnimatedPositioned(
                duration: AppSpacing.durationMedium,
                curve: AppSpacing.curveSmooth,
                left: isSignIn ? 0.0 : tabWidth,
                top: 0.0,
                bottom: 0.0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Sign In',
                      isActive: isSignIn,
                      onTap: () => onChanged(AuthMode.signIn),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Create Account',
                      isActive: !isSignIn,
                      onTap: () => onChanged(AuthMode.signUp),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: AppSpacing.durationFast,
          style: AppTypography.labelLarge.copyWith(
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppColors.textPrimaryDark
                : AppColors.textTertiaryDark,
          ),
          child: Text(title),
        ),
      ),
    );
  }
}
