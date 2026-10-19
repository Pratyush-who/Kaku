import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Modern squircle/pill input field with animated focus glow and chip icons (Rule 12 & 24).
/// "dont use a square for details make a professional and cool ui"
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isObscure = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 13.0,
                  color: _isFocused
                      ? AppColors.accentPrimary
                      : AppColors.textSecondaryDark,
                ),
              ),
              if (hasError)
                Text(
                  _errorText!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.error,
                    fontSize: 11.0,
                  ),
                ),
            ],
          ),
        ),

        // Glowing Squircle Container
        AnimatedContainer(
          duration: AppSpacing.durationFast,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : _isFocused
                      ? AppColors.accentPrimary
                      : AppColors.darkBorder,
              width: _isFocused ? 1.6 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: hasError
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.accentPrimary.withValues(alpha: 0.18),
                      blurRadius: 14.0,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText ? _isObscure : false,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryDark,
              fontSize: 14.5,
            ),
            cursorColor: AppColors.accentPrimary,
            onChanged: (val) {
              if (widget.validator != null) {
                setState(() {
                  _errorText = widget.validator!(val);
                });
              }
              widget.onChanged?.call(val);
            },
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 16.0,
              ),
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryDark,
                fontSize: 14.0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                      child: Container(
                        width: 34.0,
                        height: 34.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isFocused
                              ? AppColors.accentPrimary.withValues(alpha: 0.12)
                              : AppColors.darkSurfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: 17.0,
                          color: _isFocused
                              ? AppColors.accentPrimary
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 54.0,
                minHeight: 34.0,
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _isObscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20.0,
                        color: AppColors.textTertiaryDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
