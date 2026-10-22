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

/// Sign Up form fields and actions with robust validation and autofill.
/// Mirrors SignInForm for identical visual structure.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthCubit>().signUp(
          fullName: name,
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name Input
              AppTextField(
                label: 'Full Name',
                hintText: 'Pratyush Sharma',
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Email Input
              AppTextField(
                label: 'Work Email',
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
                hintText: 'At least 8 characters',
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                onSubmitted: (_) => _submit(),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  if (val.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14.0),

              // Terms Agreement Checkbox
              InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  setState(() {
                    _agreeTerms = !_agreeTerms;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppSpacing.durationFast,
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          color: _agreeTerms
                              ? AppColors.accentPrimary
                              : AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: _agreeTerms
                                ? AppColors.accentPrimary
                                : AppColors.darkBorder,
                            width: 1.2,
                          ),
                          boxShadow: _agreeTerms
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                                    blurRadius: 6.0,
                                  ),
                                ]
                              : [],
                        ),
                        child: _agreeTerms
                            ? const Icon(
                                Icons.check,
                                size: 14.0,
                                color: Color(0xFF090B10),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'I agree to the Workspace & Privacy Terms',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Primary Create Account Button (Gradient Pill with Arrow)
              AppButton(
                text: 'Create Free Workspace',
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
          ),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.darkBorder],
              ),
            ),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkBorder, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

