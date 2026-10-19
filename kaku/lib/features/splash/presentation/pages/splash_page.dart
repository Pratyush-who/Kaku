import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/widgets/app_brand_logo.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Polished Splash Screen with breathing glow, logo reveal, and smooth navigation (Rule 27 & 29).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // Smooth transition to Auth after splash display
    _navTimer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        context.go(AppRoutes.auth);
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Atmospheric Radial Glow Aura
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            child: Container(
              width: 320.0,
              height: 320.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPrimary.withValues(alpha: 0.16),
                    AppColors.accentSecondary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Background Canvas Dots
          Positioned.fill(
            child: CustomPaint(
              painter: _SplashDotsPainter(),
            ),
          ),

          // Center Logo Reveal & Tagline
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Stylized Logo Mark
                    const AppBrandLogo(
                      size: 72.0,
                      fontSize: 34.0,
                      subtitle: 'Persistent Collaborative Drawing',
                    ),
                    const SizedBox(height: 36.0),

                    // Luminous Progress Pill
                    Container(
                      width: 140.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        child: const LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentPrimary,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'INITIALIZING WORKSPACE',
                      style: AppTypography.brandTagline.copyWith(
                        fontSize: 10.0,
                        letterSpacing: 2.8,
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Tagline
          Positioned(
            bottom: 40.0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                '${AppConstants.appName} • ${AppConstants.appJapaneseKanji}',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 3.0,
                  color: AppColors.textDisabledDark,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    for (var x = 18.0; x < size.width; x += spacing) {
      for (var y = 18.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashDotsPainter oldDelegate) => false;
}
