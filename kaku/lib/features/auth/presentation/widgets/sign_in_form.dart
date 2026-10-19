import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/widgets/app_button.dart';
import '../../../../core/common/widgets/app_social_button.dart';
import '../../../../core/common/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Sign In form fields and actions (Rule 2 & 10).
/// Uses organic rounded squircle inputs and pill buttons ("dont use a square for details").
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthCubit>().signIn(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Input
            AppTextField(
              label: 'Email Address',
              hintText: 'name@workspace.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Email is required';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Password Input
            AppTextField(
              label: 'Password',
              hintText: 'Enter your password',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              onSubmitted: (_) => _submit(),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Password is required';
                if (val.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12.0),

            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppSpacing.durationFast,
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppColors.accentPrimary
                              : AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: _rememberMe
                                ? AppColors.accentPrimary
                                : AppColors.darkBorder,
                            width: 1.2,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 14.0,
                                color: Color(0xFF090B10),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Remember me',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset link will be sent to your email.'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Primary Sign In Button (Gradient Pill with Arrow)
            AppButton(
              text: 'Sign In to Workspace',
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 18.0,
                color: Color(0xFF090B10),
              ),
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 22.0),

            // Divider: "or continue with"
            _buildDivider(),
            const SizedBox(height: 18.0),

            // Social Logins (Google, Apple, GitHub)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSocialButton(
                  provider: SocialProvider.google,
                  onPressed: () => context
                      .read<AuthCubit>()
                      .signInWithSocial('Google'),
                ),
                const SizedBox(width: 16.0),
                AppSocialButton(
                  provider: SocialProvider.apple,
                  onPressed: () => context
                      .read<AuthCubit>()
                      .signInWithSocial('Apple'),
                ),
                const SizedBox(width: 16.0),
                AppSocialButton(
                  provider: SocialProvider.github,
                  onPressed: () => context
                      .read<AuthCubit>()
                      .signInWithSocial('GitHub'),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Terms Notice
            Text(
              AppConstants.termsNotice,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.0,
                color: AppColors.textTertiaryDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.0,
            color: AppColors.darkBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            'or continue with',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiaryDark,
              fontSize: 11.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.0,
            color: AppColors.darkBorder,
          ),
        ),
      ],
    );
  }
}
