import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Interactive Floating Canvas Hero showcasing Kaku's drawing & live collaboration DNA.
/// Features floating artboard nodes, dynamic bezier connectors with live pulses,
/// and collaborative collaborator cursors with drawing trails.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive card spacing
        final isCompact = width < 380;
        final leftCardOffset = isCompact ? 8.0 : 16.0;
        final rightCardOffset = isCompact ? 8.0 : 16.0;

        return AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final floatValue = math.sin(_floatController.value * 2 * math.pi);
            final cosValue = math.cos(_floatController.value * 2 * math.pi);

            return SizedBox(
              height: 200.0,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Atmospheric Ambient Glow Aura
                  Positioned(
                    top: 15.0,
                    child: Container(
                      width: width * 0.75,
                      height: 130.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accentPrimary.withValues(alpha: 0.16 + (floatValue * 0.04)),
                            AppColors.accentSecondary.withValues(alpha: 0.09),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Dynamic Canvas Grid & Animated Pulsing Connector
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CanvasConnectorsPainter(
                        progress: _floatController.value,
                        isCompact: isCompact,
                      ),
                    ),
                  ),

                  // Node 1: System Architecture (Left floating card)
                  Positioned(
                    left: leftCardOffset,
                    top: 36.0 + (floatValue * 6.0),
                    child: Transform.rotate(
                      angle: -0.05,
                      child: _buildCanvasNode(
                        icon: Icons.hub_outlined,
                        title: 'Architecture',
                        subtitle: 'PostgreSQL • API',
                        color: AppColors.accentSecondary,
                        isCompact: isCompact,
                      ),
                    ),
                  ),

                  // Node 2: Interactive Whiteboard (Right floating card)
                  Positioned(
                    right: rightCardOffset,
                    top: 22.0 - (floatValue * 7.0),
                    child: Transform.rotate(
                      angle: 0.04,
                      child: _buildCanvasNode(
                        icon: Icons.draw_outlined,
                        title: 'Whiteboard',
                        subtitle: 'Live session #42',
                        color: AppColors.accentPrimary,
                        isCompact: isCompact,
                      ),
                    ),
                  ),

                  // Collaborator Cursor 1: "Pratyush" with Drawing Trail
                  Positioned(
                    left: (width * 0.28) + (floatValue * 14.0),
                    top: 104.0 + (cosValue * 6.0),
                    child: _buildCursorBadge(
                      name: 'Pratyush',
                      color: AppColors.accentPrimary,
                      isDrawing: true,
                    ),
                  ),

                  // Collaborator Cursor 2: "Alex" (Viewing Node)
                  Positioned(
                    right: (width * 0.22) - (cosValue * 12.0),
                    top: 122.0 - (floatValue * 6.0),
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
      },
    );
  }

  Widget _buildCanvasNode({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10.0 : 13.0,
        vertical: isCompact ? 8.0 : 10.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: color.withValues(alpha: 0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18.0,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 15.0, color: color),
          ),
          const SizedBox(width: 9.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Container(
                    width: 5.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color,
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: isCompact ? 9.5 : 10.0,
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
            size: 15.0,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 6.0,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10.0,
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
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF090B10),
                ),
              ),
              if (isDrawing) ...[
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.edit_rounded,
                  size: 9.0,
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
  _CanvasConnectorsPainter({
    required this.progress,
    required this.isCompact,
  });

  final double progress;
  final bool isCompact;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle drafting grid dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    for (var x = 15.0; x < size.width; x += spacing) {
      for (var y = 10.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
      }
    }

    // 2. Smooth bezier connector line between nodes
    final path = Path();
    final startX = size.width * (isCompact ? 0.32 : 0.28);
    final startY = size.height * 0.44;
    final endX = size.width * (isCompact ? 0.68 : 0.72);
    final endY = size.height * 0.38;

    path.moveTo(startX, startY);
    path.cubicTo(
      size.width * 0.42,
      size.height * 0.16,
      size.width * 0.58,
      size.height * 0.76,
      endX,
      endY,
    );

    // Connector background track
    final trackPaint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, trackPaint);

    // 3. Flowing Pulse Signal along connector
    final metric = path.computeMetrics().firstOrNull;
    if (metric != null) {
      final length = metric.length;
      final pulsePos = (progress * length) % length;
      final tangent = metric.getTangentForOffset(pulsePos);
      if (tangent != null) {
        final pulsePaint = Paint()
          ..color = AppColors.accentPrimary
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(tangent.position, 4.0, pulsePaint);

        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tangent.position, 1.8, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasConnectorsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
