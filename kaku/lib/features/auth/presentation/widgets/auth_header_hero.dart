import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Interactive Floating Canvas Hero showcasing Kaku's drawing & live collaboration DNA.
/// Features floating artboard cards, bezier connectors, and live collaborator cursors (Rule 13 & 29).
class AuthHeaderHero extends StatefulWidget {
  const AuthHeaderHero({super.key});

  @override
  State<AuthHeaderHero> createState() => _AuthHeaderHeroState();
}

class _AuthHeaderHeroState extends State<AuthHeaderHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final floatValue = math.sin(_floatController.value * 2 * math.pi);

        return SizedBox(
          height: 200.0,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Background Ambient Glow Aura
              Positioned(
                top: 20.0,
                child: Container(
                  width: 220.0,
                  height: 120.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentPrimary.withValues(alpha: 0.18),
                        AppColors.accentSecondary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Canvas Grid & Connector Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _CanvasConnectorsPainter(progress: _floatController.value),
                ),
              ),

              // Card 1: System Architecture Node (Left floating card)
              Positioned(
                left: 16.0,
                top: 40.0 + (floatValue * 6.0),
                child: Transform.rotate(
                  angle: -0.06,
                  child: _buildCanvasNode(
                    icon: Icons.hub_outlined,
                    title: 'Architecture',
                    subtitle: 'PostgreSQL • API',
                    color: AppColors.accentSecondary,
                  ),
                ),
              ),

              // Card 2: Interactive Wireframe Node (Right floating card)
              Positioned(
                right: 16.0,
                top: 25.0 - (floatValue * 7.0),
                child: Transform.rotate(
                  angle: 0.05,
                  child: _buildCanvasNode(
                    icon: Icons.draw_outlined,
                    title: 'Whiteboard',
                    subtitle: 'Live session #42',
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),

              // Floating Collaborator Cursor: "Pratyush"
              Positioned(
                left: 100.0 + (floatValue * 12.0),
                top: 110.0 + (floatValue * 4.0),
                child: _buildCursorBadge(
                  name: 'Pratyush',
                  color: AppColors.accentPrimary,
                  isDrawing: true,
                ),
              ),

              // Floating Collaborator Cursor: "Alex"
              Positioned(
                right: 60.0 - (floatValue * 10.0),
                top: 130.0 - (floatValue * 5.0),
                child: _buildCursorBadge(
                  name: 'Alex',
                  color: AppColors.accentCyan,
                  isDrawing: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvasNode({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16.0,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, size: 16.0, color: color),
          ),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10.0,
                  color: AppColors.textTertiaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCursorBadge({
    required String name,
    required Color color,
    required bool isDrawing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrow Pointer Icon
        Transform.rotate(
          angle: -0.4,
          child: Icon(
            Icons.navigation_rounded,
            size: 16.0,
            color: color,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF090B10),
                ),
              ),
              if (isDrawing) ...[
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.edit,
                  size: 8.5,
                  color: Color(0xFF090B10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CanvasConnectorsPainter extends CustomPainter {
  _CanvasConnectorsPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Smooth bezier curve connecting left and right nodes
    path.moveTo(size.width * 0.28, size.height * 0.42);
    path.cubicTo(
      size.width * 0.45,
      size.height * 0.15,
      size.width * 0.55,
      size.height * 0.75,
      size.width * 0.72,
      size.height * 0.38,
    );

    canvas.drawPath(path, paint);

    // Subtle background dots for infinite canvas feel
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (var x = 20.0; x < size.width; x += 32.0) {
      for (var y = 10.0; y < size.height; y += 32.0) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasConnectorsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
