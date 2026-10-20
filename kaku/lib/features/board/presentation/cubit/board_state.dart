import 'package:flutter/material.dart';
import '../../../../core/models/board_model.dart';

enum CanvasTool {
  pen,
  highlighter,
  rectangle,
  circle,
  line,
  arrow,
  text,
  eraser,
}

enum ElementType {
  stroke,
  highlighter,
  rectangle,
  circle,
  line,
  arrow,
  text,
}

class CanvasElement {
  final String id;
  final ElementType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String text;

  const CanvasElement({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.text = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'text': text,
    };
  }

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? [];
    final points = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['x'] as num?)?.toDouble() ?? 0.0,
        (map['y'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    ElementType parseType(String? name) {
      for (final val in ElementType.values) {
        if (val.name == name) return val;
      }
      return ElementType.stroke;
    }

    final rawColor = json['color'] as num? ?? 0xFF00F2A9;
    return CanvasElement(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type: parseType(json['type'] as String?),
      points: points,
      color: Color(rawColor.toInt()),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      text: json['text'] as String? ?? '',
    );
  }

  CanvasElement copyWith({
    String? id,
    ElementType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    String? text,
  }) {
    return CanvasElement(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      text: text ?? this.text,
    );
  }
}

sealed class BoardState {
  const BoardState();
}

final class BoardInitial extends BoardState {
  const BoardInitial();
}

final class BoardLoading extends BoardState {
  const BoardLoading({this.message = 'Loading board canvas...'});
  final String message;
}

final class BoardLoaded extends BoardState {
  const BoardLoaded({
    required this.board,
    required this.elements,
    this.activeTool = CanvasTool.pen,
    this.selectedColor = const Color(0xFF00F2A9),
    this.strokeWidth = 3.5,
    this.isSaving = false,
    this.hasUnsavedChanges = false,
    this.saveStatus = 'Saved',
    this.undoStack = const [],
    this.redoStack = const [],
    this.currentRevision = 0,
    this.statusMessage,
  });

  final BoardModel board;
  final List<CanvasElement> elements;
  final CanvasTool activeTool;
  final Color selectedColor;
  final double strokeWidth;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final String saveStatus;
  final List<List<CanvasElement>> undoStack;
  final List<List<CanvasElement>> redoStack;
  final int currentRevision;
  final String? statusMessage;

  BoardLoaded copyWith({
    BoardModel? board,
    List<CanvasElement>? elements,
    CanvasTool? activeTool,
    Color? selectedColor,
    double? strokeWidth,
    bool? isSaving,
    bool? hasUnsavedChanges,
    String? saveStatus,
    List<List<CanvasElement>>? undoStack,
    List<List<CanvasElement>>? redoStack,
    int? currentRevision,
    String? statusMessage,
  }) {
    return BoardLoaded(
      board: board ?? this.board,
      elements: elements ?? this.elements,
      activeTool: activeTool ?? this.activeTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      saveStatus: saveStatus ?? this.saveStatus,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      currentRevision: currentRevision ?? this.currentRevision,
      statusMessage: statusMessage,
    );
  }
}

final class BoardError extends BoardState {
  const BoardError(this.errorMessage);
  final String errorMessage;
}
