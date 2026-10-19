import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Modern geometric vector brand mark for Kaku (Rule 10 & Rule 27).
/// Combines an infinite canvas loop, pencil stroke, and stylized "K".
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 40.0,
    this.showWordmark = true,
    this.fontSize = 20.0,
    this.subtitle,
  });

  final double size;
  final bool showWordmark;
  final double fontSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Vector Glyph Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.35),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.35),
                blurRadius: size * 0.5,
                spreadRadius: 1.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _LogoMarkPainter(),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KAKU',
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: AppColors.accentPrimary.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '描く',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2.0),
                Text(
                  subtitle!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiaryDark,
                    fontSize: fontSize * 0.55,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF090B10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Stylized "K" intersecting with dynamic canvas drawing stroke
    final path = Path();
    // Vertical spine of K
    path.moveTo(w * 0.32, h * 0.24);
    path.lineTo(w * 0.32, h * 0.76);

    // Upper diagonal stroke
    path.moveTo(w * 0.68, h * 0.28);
    path.lineTo(w * 0.34, h * 0.52);

    // Lower diagonal stroke with stylus hook
    path.moveTo(w * 0.40, h * 0.48);
    path.lineTo(w * 0.70, h * 0.74);

    canvas.drawPath(path, paint);

    // Glowing stylus point dot
    final dotPaint = Paint()
      ..color = const Color(0xFF090B10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.72, h * 0.26), size.width * 0.07, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
