import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/auth_state.dart';

/// Smooth sliding pill tab switcher for toggling between Sign In and Sign Up.
/// Enforces organic pill geometry with glowing active state.
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
      height: 50.0,
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
          final tabWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // Sliding Animated Pill Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: isSignIn ? 0.0 : tabWidth,
                top: 0.0,
                bottom: 0.0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.darkSurfaceElevated,
                        Color(0xFF222C3E),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.45),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                        blurRadius: 10.0,
                        spreadRadius: 0.5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6.0,
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
                      icon: Icons.login_rounded,
                      isActive: isSignIn,
                      onTap: () => onChanged(AuthMode.signIn),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Create Account',
                      icon: Icons.person_add_outlined,
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
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.0,
              color: isActive
                  ? AppColors.accentPrimary
                  : AppColors.textTertiaryDark,
            ),
            const SizedBox(width: 6.0),
            AnimatedDefaultTextStyle(
              duration: AppSpacing.durationFast,
              style: AppTypography.labelLarge.copyWith(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.textPrimaryDark
                    : AppColors.textTertiaryDark,
                letterSpacing: 0.2,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }
}

