import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/board_cubit.dart';
import '../cubit/board_state.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({super.key, required this.boardId});

  final String boardId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BoardCubit(boardId: boardId)..loadBoard(),
      child: const _BoardView(),
    );
  }
}

class _BoardView extends StatefulWidget {
  const _BoardView();

  @override
  State<_BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<_BoardView> {
  CanvasElement? _activeElement;

  void _showRenameDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Rename Board', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                context.read<BoardCubit>().renameBoard(newName);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddTextDialog(BuildContext context, Offset position) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text('Add Sticky Note / Text', style: AppTypography.titleMedium),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type your note...',
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textCtrl.text.trim();
              if (text.isNotEmpty) {
                final cubit = context.read<BoardCubit>();
                final state = cubit.state as BoardLoaded;
                final el = CanvasElement(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: ElementType.text,
                  points: [position],
                  color: state.selectedColor,
                  strokeWidth: state.strokeWidth,
                  text: text,
                );
                cubit.addElement(el);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary, foregroundColor: Colors.black),
            child: const Text('Add to Board'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: SafeArea(
        child: BlocConsumer<BoardCubit, BoardState>(
          listener: (context, state) {
            if (state is BoardLoaded && state.statusMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.statusMessage!), behavior: SnackBarBehavior.floating),
              );
            }
          },
          builder: (context, state) {
            if (state is BoardLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
            }
            if (state is BoardError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 40.0),
                    const SizedBox(height: 12.0),
                    Text(state.errorMessage, style: AppTypography.bodyMedium),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () => context.read<BoardCubit>().loadBoard(),
                      child: const Text('Reload Board'),
                    ),
                  ],
                ),
              );
            }
            if (state is BoardLoaded) {
              return Stack(
                children: [
                  // Drawing Surface Area
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        final pos = details.localPosition;
                        if (state.activeTool == CanvasTool.text) {
                          _showAddTextDialog(context, pos);
                          return;
                        }

                        ElementType elType = ElementType.stroke;
                        if (state.activeTool == CanvasTool.highlighter) {
                          elType = ElementType.highlighter;
                        } else if (state.activeTool == CanvasTool.rectangle) {
                          elType = ElementType.rectangle;
                        } else if (state.activeTool == CanvasTool.circle) {
                          elType = ElementType.circle;
                        } else if (state.activeTool == CanvasTool.arrow) {
                          elType = ElementType.arrow;
                        }

                        setState(() {
                          _activeElement = CanvasElement(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            type: elType,
                            points: [pos],
                            color: state.selectedColor,
                            strokeWidth: state.activeTool == CanvasTool.highlighter
                                ? state.strokeWidth * 3.5
                                : state.strokeWidth,
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        if (_activeElement == null) return;
                        final pos = details.localPosition;
                        setState(() {
                          if (_activeElement!.type == ElementType.rectangle ||
                              _activeElement!.type == ElementType.circle ||
                              _activeElement!.type == ElementType.arrow) {
                            _activeElement = _activeElement!.copyWith(
                              points: [_activeElement!.points.first, pos],
                            );
                          } else {
                            final newPoints = List<Offset>.from(_activeElement!.points)..add(pos);
                            _activeElement = _activeElement!.copyWith(points: newPoints);
                          }
                        });
                      },
                      onPanEnd: (details) {
                        if (_activeElement != null) {
                          context.read<BoardCubit>().addElement(_activeElement!);
                          setState(() {
                            _activeElement = null;
                          });
                        }
                      },
                      child: CustomPaint(
                        painter: _BoardCanvasPainter(
                          elements: state.elements,
                          activeElement: _activeElement,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),

                  // Top Header Bar
                  Positioned(
                    top: 10.0,
                    left: 14.0,
                    right: 14.0,
                    child: _buildHeaderBar(context, state),
                  ),

                  // Floating Tool Palette (Bottom)
                  Positioned(
                    bottom: 16.0,
                    left: 14.0,
                    right: 14.0,
                    child: _buildToolPalette(context, state),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, BoardLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.0),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: InkWell(
              onTap: () => _showRenameDialog(context, state.board.name),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      state.board.name,
                      style: AppTypography.titleMedium.copyWith(fontSize: 15.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  const Icon(Icons.edit_outlined, color: AppColors.textTertiaryDark, size: 14.0),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Revision Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.darkBorder, width: 0.8),
            ),
            child: Text(
              'REV ${state.currentRevision}',
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Save Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: state.isSaving
                  ? AppColors.info.withValues(alpha: 0.15)
                  : (state.hasUnsavedChanges
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isSaving)
                  const SizedBox(
                    width: 10.0,
                    height: 10.0,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.info),
                  )
                else
                  Icon(
                    state.hasUnsavedChanges ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                    size: 13.0,
                    color: state.hasUnsavedChanges ? AppColors.warning : AppColors.success,
                  ),
                const SizedBox(width: 5.0),
                Text(
                  state.saveStatus,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: state.isSaving
                        ? AppColors.info
                        : (state.hasUnsavedChanges ? AppColors.warning : AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),

          // Save Now Button
          InkWell(
            onTap: state.isSaving ? null : () => context.read<BoardCubit>().saveBoard(),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolPalette(BuildContext context, BoardLoaded state) {
    final colors = [
      const Color(0xFF00F2A9), // Aurora Emerald
      const Color(0xFF00D2FF), // Cyan Flare
      const Color(0xFFA855F7), // Violet Sketch
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFFFFFFF), // White
      const Color(0xFF94A3B8), // Gray
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.darkBorderHighlight, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tools Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _toolButton(context, CanvasTool.pen, Icons.edit_rounded, state),
                _toolButton(context, CanvasTool.highlighter, Icons.brush_rounded, state),
                _toolButton(context, CanvasTool.rectangle, Icons.crop_square_rounded, state),
                _toolButton(context, CanvasTool.circle, Icons.circle_outlined, state),
                _toolButton(context, CanvasTool.arrow, Icons.arrow_outward_rounded, state),
                _toolButton(context, CanvasTool.text, Icons.sticky_note_2_outlined, state),
                _toolButton(context, CanvasTool.eraser, Icons.auto_fix_high_rounded, state),

                Container(width: 1.0, height: 24.0, color: AppColors.darkBorder, margin: const EdgeInsets.symmetric(horizontal: 8.0)),

                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20.0),
                  color: state.undoStack.isNotEmpty ? Colors.white : AppColors.textDisabledDark,
                  onPressed: state.undoStack.isNotEmpty ? () => context.read<BoardCubit>().undo() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, size: 20.0),
                  color: state.redoStack.isNotEmpty ? Colors.white : AppColors.textDisabledDark,
                  onPressed: state.redoStack.isNotEmpty ? () => context.read<BoardCubit>().redo() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20.0, color: AppColors.error),
                  onPressed: state.elements.isNotEmpty ? () => context.read<BoardCubit>().clearCanvas() : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Color & Stroke Width Row
          Row(
            children: [
              // Colors
              ...colors.map((c) => GestureDetector(
                    onTap: () => context.read<BoardCubit>().setColor(c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 22.0,
                      height: 22.0,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: state.selectedColor.toARGB32() == c.toARGB32() ? Colors.white : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                  )),
              const Spacer(),

              // Stroke Width Presets
              _strokeWidthPreset(context, 2.0, 'Thin', state),
              const SizedBox(width: 6.0),
              _strokeWidthPreset(context, 4.0, 'Med', state),
              const SizedBox(width: 6.0),
              _strokeWidthPreset(context, 8.0, 'Bold', state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolButton(BuildContext context, CanvasTool tool, IconData icon, BoardLoaded state) {
    final isSelected = state.activeTool == tool;
    return IconButton(
      icon: Icon(icon, size: 20.0),
      color: isSelected ? AppColors.accentPrimary : AppColors.textSecondaryDark,
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: AppColors.accentPrimary.withValues(alpha: 0.15))
          : null,
      onPressed: () => context.read<BoardCubit>().setTool(tool),
    );
  }

  Widget _strokeWidthPreset(BuildContext context, double width, String label, BoardLoaded state) {
    final isSelected = (state.strokeWidth - width).abs() < 0.5;
    return InkWell(
      onTap: () => context.read<BoardCubit>().setStrokeWidth(width),
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.darkBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentPrimary : AppColors.textTertiaryDark,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BoardCanvasPainter extends CustomPainter {
  const _BoardCanvasPainter({required this.elements, this.activeElement});

  final List<CanvasElement> elements;
  final CanvasElement? activeElement;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Subtle Dot Grid
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (var x = 16.0; x < size.width; x += spacing) {
      for (var y = 16.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    // 2. Draw Committed Elements
    for (final el in elements) {
      _drawElement(canvas, el);
    }

    // 3. Draw Active In-Progress Element
    if (activeElement != null) {
      _drawElement(canvas, activeElement!);
    }
  }

  void _drawElement(Canvas canvas, CanvasElement el) {
    if (el.points.isEmpty) return;

    final paint = Paint()
      ..color = el.type == ElementType.highlighter
          ? el.color.withValues(alpha: 0.35)
          : el.color
      ..strokeWidth = el.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (el.type) {
      case ElementType.stroke:
      case ElementType.highlighter:
        if (el.points.length == 1) {
          canvas.drawCircle(el.points.first, el.strokeWidth / 2, paint..style = PaintingStyle.fill);
        } else {
          final path = Path()..moveTo(el.points.first.dx, el.points.first.dy);
          for (int i = 1; i < el.points.length; i++) {
            path.lineTo(el.points[i].dx, el.points[i].dy);
          }
          canvas.drawPath(path, paint);
        }
        break;

      case ElementType.rectangle:
        if (el.points.length >= 2) {
          final rect = Rect.fromPoints(el.points.first, el.points.last);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8.0)), paint);
        }
        break;

      case ElementType.circle:
        if (el.points.length >= 2) {
          final p1 = el.points.first;
          final p2 = el.points.last;
          final rect = Rect.fromPoints(p1, p2);
          canvas.drawOval(rect, paint);
        }
        break;

      case ElementType.line:
      case ElementType.arrow:
        if (el.points.length >= 2) {
          final start = el.points.first;
          final end = el.points.last;
          canvas.drawLine(start, end, paint);

          if (el.type == ElementType.arrow) {
            // Draw Arrowhead
            const arrowAngle = 25 * math.pi / 180;
            const arrowLength = 16.0;
            final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

            final arrowPath = Path()
              ..moveTo(end.dx, end.dy)
              ..lineTo(
                end.dx - arrowLength * math.cos(angle - arrowAngle),
                end.dy - arrowLength * math.sin(angle - arrowAngle),
              )
              ..moveTo(end.dx, end.dy)
              ..lineTo(
                end.dx - arrowLength * math.cos(angle + arrowAngle),
                end.dy - arrowLength * math.sin(angle + arrowAngle),
              );
            canvas.drawPath(arrowPath, paint);
          }
        }
        break;

      case ElementType.text:
        final origin = el.points.first;
        // Draw Sticky Note Background
        final noteRect = Rect.fromLTWH(origin.dx, origin.dy, 160.0, 90.0);
        final bgPaint = Paint()
          ..color = el.color.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = el.color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawRRect(RRect.fromRectAndRadius(noteRect, const Radius.circular(10.0)), bgPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(noteRect, const Radius.circular(10.0)), borderPaint);

        // Draw Text inside Note
        final textPainter = TextPainter(
          text: TextSpan(
            text: el.text,
            style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 4,
          ellipsis: '...',
        );
        textPainter.layout(maxWidth: 140.0);
        textPainter.paint(canvas, Offset(origin.dx + 10.0, origin.dy + 10.0));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BoardCanvasPainter oldDelegate) => true;
}
