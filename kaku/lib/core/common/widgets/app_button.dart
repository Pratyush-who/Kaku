import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// Tactile, modern pill button with glowing gradients and micro-interactions (Rule 9 & 29).
/// Enforces organic pill geometry instead of boxy buttons ("dont use a square for details").
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.leading,
    this.trailing,
    this.height = 56.0,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final double? width;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.isLoading && widget.onPressed != null) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.isLoading && widget.onPressed != null) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading && widget.onPressed != null) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: _buildDecoration(isDisabled),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              onTap: isDisabled ? null : widget.onPressed,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22.0,
                        height: 22.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.variant == AppButtonVariant.primary
                                ? const Color(0xFF090B10)
                                : AppColors.accentPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leading != null) ...[
                            widget.leading!,
                            const SizedBox(width: 8.0),
                          ],
                          Text(
                            widget.text,
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: _getTextColor(isDisabled),
                            ),
                          ),
                          if (widget.trailing != null) ...[
                            const SizedBox(width: 8.0),
                            widget.trailing!,
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDisabled) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
                  colors: [
                    AppColors.accentPrimary.withValues(alpha: 0.3),
                    AppColors.accentCyan.withValues(alpha: 0.3),
                  ],
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.32),
                    blurRadius: 18.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 6),
                  ),
                ],
        );

      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: AppColors.darkBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        );
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.textDisabledDark;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return const Color(0xFF090B10);
      case AppButtonVariant.secondary:
        return AppColors.textPrimaryDark;
      case AppButtonVariant.ghost:
        return AppColors.accentPrimary;
    }
  }
}
