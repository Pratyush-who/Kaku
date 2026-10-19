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

/// Sign Up form fields and actions (Rule 2 & 10).
/// Mirrors SignInForm for identical visual structure ("keep the pages identical").
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
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue.'),
        ),
      );
      return;
    }
    context.read<AuthCubit>().signUp(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
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
            const SizedBox(height: 12.0),

            // Terms Agreement Checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  _agreeTerms = !_agreeTerms;
                });
              },
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
                      ),
                    ),
                  ),
                ],
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
