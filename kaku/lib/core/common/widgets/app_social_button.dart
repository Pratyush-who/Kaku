import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum SocialProvider { google, apple, github }

/// Sleek social auth buttons with tactile feedback (Rule 10 & 24).
class AppSocialButton extends StatefulWidget {
  const AppSocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.size = 54.0,
  });

  final SocialProvider provider;
  final VoidCallback onPressed;
  final double size;

  @override
  State<AppSocialButton> createState() => _AppSocialButtonState();
}

class _AppSocialButtonState extends State<AppSocialButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.onPressed,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: AppColors.darkBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: _buildIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (widget.provider) {
      case SocialProvider.google:
        return const _GoogleIcon();
      case SocialProvider.apple:
        return const Icon(
          Icons.apple,
          color: Colors.white,
          size: 26.0,
        );
      case SocialProvider.github:
        return const Icon(
          Icons.code,
          color: AppColors.accentPrimary,
          size: 24.0,
        );
    }
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.0,
      height: 22.0,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Red sector
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    // Yellow sector
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    // Green sector
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    // Blue bar & arc
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw stylized multi-color arcs
    canvas.drawArc(rect, 3.14 * 0.75, 3.14 * 0.5, true, redPaint);
    canvas.drawArc(rect, 3.14 * 0.25, 3.14 * 0.5, true, greenPaint);
    canvas.drawArc(rect, 3.14 * 1.25, 3.14 * 0.5, true, yellowPaint);
    canvas.drawArc(rect, 3.14 * 1.75, 3.14 * 0.5, true, bluePaint);

    // Inner cutout circle
    final innerPaint = Paint()..color = AppColors.darkSurfaceElevated;
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = radius * 0.42
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(w * 0.45, h * 0.5),
      Offset(w * 0.96, h * 0.5),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
