import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/constants/app_constants.dart';
import '../../../../core/common/widgets/app_brand_logo.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Ultra-polished Splash Screen with breathing aurora aura, animated drafting canvas,
/// orbital drawing arc around brand mark, and luminous progress indicator.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  late final Animation<double> _progressAnimation;

  Timer? _navTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Orchestrated entrance animation (1600ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Continuous subtle breathing and particle motion
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _entranceController.forward();

    // Check auth and transition smoothly
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final stopwatch = Stopwatch()..start();
    final user = await AuthRepository().checkAuthStatus();
    final elapsed = stopwatch.elapsedMilliseconds;
    final remainingWait = math.max(0, 2000 - elapsed);

    _navTimer = Timer(Duration(milliseconds: remainingWait), () {
      if (mounted) {
        setState(() => _isExiting = true);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            if (user != null) {
              context.go(AppRoutes.projects);
            } else {
              context.go(AppRoutes.auth);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      opacity: _isExiting ? 0.0 : 1.0,
      curve: Curves.easeOutCubic,
      child: Scaffold(
        backgroundColor: AppColors.darkCanvas,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Background Dynamic Atmospheric Glow & Canvas Grid
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SplashAtmospherePainter(
                      pulseProgress: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // Center: Animated Logo, Drawing Arc, Progress Beam & Status
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo with Orbiting Stylus Arc
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Orbital Drawing Arc Painter
                                CustomPaint(
                                  size: const Size(120.0, 120.0),
                                  painter: _OrbitalStylusArcPainter(
                                    progress: _entranceController.value,
                                    pulse: _pulseController.value,
                                  ),
                                ),
                                // Brand Logo Mark
                                child!,
                              ],
                            );
                          },
                          child: const AppBrandLogo(
                            size: 76.0,
                            fontSize: 34.0,
                            subtitle: 'Persistent Collaborative Drawing',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40.0),

                    // Staggered Entrance for Progress Beam & Status Text
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Custom Luminous Progress Beam
                            _buildProgressBeam(),

                            const SizedBox(height: 18.0),

                            // Dynamic Status Text
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, _) {
                                final p = _progressAnimation.value;
                                String statusText;
                                if (p < 0.35) {
                                  statusText = 'INITIALIZING WORKSPACE';
                                } else if (p < 0.75) {
                                  statusText = 'CONNECTING COLLABORATIVE ENGINE';
                                } else {
                                  statusText = 'READY TO DRAW • 描く';
                                }

                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  child: Text(
                                    statusText,
                                    key: ValueKey(statusText),
                                    style: AppTypography.brandTagline.copyWith(
                                      fontSize: 10.5,
                                      letterSpacing: 2.8,
                                      fontWeight: FontWeight.w700,
                                      color: p > 0.7
                                          ? AppColors.accentPrimary
                                          : AppColors.textTertiaryDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Brand Japanese Monogram & Version
            Positioned(
              bottom: 40.0,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard.withValues(alpha: 0.7),
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
                          const SizedBox(width: 8.0),
                          Text(
                            '${AppConstants.appName} • ${AppConstants.appJapaneseKanji}',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 2.6,
                              color: AppColors.textSecondaryDark,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBeam() {
    return Container(
      width: 170.0,
      height: 5.0,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 0.8,
        ),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          final progress = _progressAnimation.value.clamp(0.0, 1.0);
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.6),
                      blurRadius: 8.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints the orbital stylus drawing arc surrounding the brand logo
class _OrbitalStylusArcPainter extends CustomPainter {
  _OrbitalStylusArcPainter({
    required this.progress,
    required this.pulse,
  });

  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.52;

    // Glowing track paint
    final trackPaint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.06 + (pulse * 0.04))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, trackPaint);

    // Dynamic drawing arc
    final arcAngle = math.pi * 1.8 * progress;
    final startAngle = -math.pi / 2 + (pulse * 0.2);

    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.accentSecondary,
          AppColors.accentPrimary,
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      arcAngle,
      false,
      sweepPaint,
    );

    // Glowing stylus tip head
    final tipAngle = startAngle + arcAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final glowPaint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset(tipX, tipY), 5.0, glowPaint);

    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 2.2, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitalStylusArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

/// Paints the infinite drafting canvas dots, coordinates crosshairs, and breathing aurora
class _SplashAtmospherePainter extends CustomPainter {
  _SplashAtmospherePainter({required this.pulseProgress});

  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dual Breathing Aurora Glows
    final centerGlowOffset = Offset(
      size.width * 0.5,
      size.height * (0.42 + (pulseProgress * 0.04)),
    );

    final auraRadius = size.width * (0.55 + (pulseProgress * 0.1));
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentPrimary.withValues(alpha: 0.14 + (pulseProgress * 0.06)),
          AppColors.accentSecondary.withValues(alpha: 0.08 + (pulseProgress * 0.04)),
          AppColors.accentCyan.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: centerGlowOffset, radius: auraRadius));

    canvas.drawCircle(centerGlowOffset, auraRadius, auraPaint);

    // 2. Drafting Canvas Dots & Coordinate Crosshairs
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + (pulseProgress * 0.02))
      ..style = PaintingStyle.fill;

    final crossPaint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.08 + (pulseProgress * 0.04))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 38.0;
    for (var x = 19.0; x < size.width; x += spacing) {
      for (var y = 19.0; y < size.height; y += spacing) {
        // Every 3rd grid point draws a tiny architectural crosshair (+)
        final colIndex = (x / spacing).round();
        final rowIndex = (y / spacing).round();

        if (colIndex % 3 == 0 && rowIndex % 3 == 0) {
          const crossSize = 3.0;
          canvas.drawLine(
            Offset(x - crossSize, y),
            Offset(x + crossSize, y),
            crossPaint,
          );
          canvas.drawLine(
            Offset(x, y - crossSize),
            Offset(x, y + crossSize),
            crossPaint,
          );
        } else {
          canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAtmospherePainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress;
}

