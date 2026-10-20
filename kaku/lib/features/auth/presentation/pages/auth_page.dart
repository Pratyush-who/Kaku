import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/widgets/app_brand_logo.dart';
import '../../../../core/common/widgets/screen_footer_brand.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/profile_settings_modal.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_header_hero.dart';
import '../widgets/auth_tab_switcher.dart';
import '../widgets/sign_in_form.dart';
import '../widgets/sign_up_form.dart';

/// Unified Auth Page for Sign In & Sign Up (Rule 2 & Rule 24).
/// Composes modular sub-widgets with identical layout structure ("keep the pages identical").
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit()..setMode(initialMode),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome to Kaku, ${state.user.name}!',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          context.go(AppRoutes.projects);
        }
      },
      builder: (context, state) {
        final isSignIn = state.mode == AuthMode.signIn;

        return Scaffold(
          backgroundColor: AppColors.darkCanvas,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12.0),

                    // Top Bar: Brand Logo & Status Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppBrandLogo(size: 34.0, fontSize: 18.0),
                        InkWell(
                          onTap: () {
                            ProfileSettingsModal.show(context);
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(
                                color: AppColors.darkBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.0,
                                  height: 6.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  'Server Setup',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const Icon(
                                  Icons.settings_outlined,
                                  size: 13.0,
                                  color: AppColors.textTertiaryDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    // Floating Interactive Canvas Hero Showcase
                    const AuthHeaderHero(),

                    const SizedBox(height: 8.0),

                    // Headline Title & Tagline
                    Text(
                      isSignIn ? AppConstants.signInTitle : AppConstants.signUpTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 26.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      isSignIn
                          ? AppConstants.signInSubtitle
                          : AppConstants.signUpSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // Pill Tab Switcher (Sign In vs Create Account)
                    AuthTabSwitcher(
                      currentMode: state.mode,
                      onChanged: (mode) =>
                          context.read<AuthCubit>().setMode(mode),
                    ),

                    const SizedBox(height: 24.0),

                    // Identical Form Container with Smooth CrossFade
                    AnimatedCrossFade(
                      duration: AppSpacing.durationMedium,
                      firstCurve: AppSpacing.curveSmooth,
                      secondCurve: AppSpacing.curveSmooth,
                      crossFadeState: isSignIn
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: const SignInForm(),
                      secondChild: const SignUpForm(),
                    ),

                    const SizedBox(height: 16.0),

                    // Screen Ending & Visual Polish (Rule 14)
                    const ScreenFooterBrand(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
