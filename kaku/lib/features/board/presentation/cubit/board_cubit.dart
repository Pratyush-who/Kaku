import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/board_repository.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardState> {
  BoardCubit({
    required this.boardId,
    BoardRepository? boardRepository,
  })  : _boardRepo = boardRepository ?? BoardRepository(),
        super(const BoardInitial());

  final String boardId;
  final BoardRepository _boardRepo;
  Timer? _autoSaveTimer;

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    return super.close();
  }

  Future<void> loadBoard() async {
    emit(const BoardLoading());
    try {
      final board = await _boardRepo.getBoard(boardId);
      final rawElements = board.content['elements'] as List? ?? [];
      final elements = rawElements
          .map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(BoardLoaded(
        board: board,
        elements: elements,
        currentRevision: board.revision,
        saveStatus: 'Saved',
      ));
    } catch (e) {
      emit(BoardError(e.toString()));
    }
  }

  void setTool(CanvasTool tool) {
    if (state is BoardLoaded) {
      emit((state as BoardLoaded).copyWith(activeTool: tool));
    }
  }

  void setColor(Color color) {
    if (state is BoardLoaded) {
      emit((state as BoardLoaded).copyWith(selectedColor: color));
    }
  }

  void setStrokeWidth(double width) {
    if (state is BoardLoaded) {
      emit((state as BoardLoaded).copyWith(strokeWidth: width));
    }
  }

  void addElement(CanvasElement element) {
    if (state is! BoardLoaded) return;
    final current = state as BoardLoaded;

    final newUndo = List<List<CanvasElement>>.from(current.undoStack)
      ..add(List<CanvasElement>.from(current.elements));

    final newElements = List<CanvasElement>.from(current.elements)..add(element);

    emit(current.copyWith(
      elements: newElements,
      undoStack: newUndo,
      redoStack: const [],
      hasUnsavedChanges: true,
      saveStatus: 'Unsaved changes',
    ));

    _scheduleAutoSave();
  }

  void undo() {
    if (state is! BoardLoaded) return;
    final current = state as BoardLoaded;
    if (current.undoStack.isEmpty) return;

    final newUndo = List<List<CanvasElement>>.from(current.undoStack);
    final previousState = newUndo.removeLast();

    final newRedo = List<List<CanvasElement>>.from(current.redoStack)
      ..add(List<CanvasElement>.from(current.elements));

    emit(current.copyWith(
      elements: previousState,
      undoStack: newUndo,
      redoStack: newRedo,
      hasUnsavedChanges: true,
      saveStatus: 'Unsaved changes',
    ));

    _scheduleAutoSave();
  }

  void redo() {
    if (state is! BoardLoaded) return;
    final current = state as BoardLoaded;
    if (current.redoStack.isEmpty) return;

    final newRedo = List<List<CanvasElement>>.from(current.redoStack);
    final nextState = newRedo.removeLast();

    final newUndo = List<List<CanvasElement>>.from(current.undoStack)
      ..add(List<CanvasElement>.from(current.elements));

    emit(current.copyWith(
      elements: nextState,
      undoStack: newUndo,
      redoStack: newRedo,
      hasUnsavedChanges: true,
      saveStatus: 'Unsaved changes',
    ));

    _scheduleAutoSave();
  }

  void clearCanvas() {
    if (state is! BoardLoaded) return;
    final current = state as BoardLoaded;
    if (current.elements.isEmpty) return;

    final newUndo = List<List<CanvasElement>>.from(current.undoStack)
      ..add(List<CanvasElement>.from(current.elements));

    emit(current.copyWith(
      elements: const [],
      undoStack: newUndo,
      redoStack: const [],
      hasUnsavedChanges: true,
      saveStatus: 'Unsaved changes',
    ));

    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1800), () {
      saveBoard();
    });
  }

  Future<void> saveBoard() async {
    if (state is! BoardLoaded) return;
    final current = state as BoardLoaded;
    if (current.isSaving) return;

    emit(current.copyWith(isSaving: true, saveStatus: 'Saving...'));

    final contentPayload = {
      'schemaVersion': 1,
      'elements': current.elements.map((e) => e.toJson()).toList(),
    };

    try {
      final newRev = await _boardRepo.updateBoardContent(
        boardId: boardId,
        content: contentPayload,
        viewport: current.board.viewport,
        expectedRevision: current.currentRevision,
      );

      final updatedBoard = current.board.copyWith(
        content: contentPayload,
        revision: newRev,
      );

      emit(current.copyWith(
        board: updatedBoard,
        currentRevision: newRev,
        isSaving: false,
        hasUnsavedChanges: false,
        saveStatus: 'Saved',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        saveStatus: 'Save failed: $e',
      ));
    }
  }

  Future<void> renameBoard(String newName) async {
    if (state is! BoardLoaded || newName.trim().isEmpty) return;
    final current = state as BoardLoaded;

    try {
      final updated = await _boardRepo.updateBoardName(boardId, newName.trim());
      emit(current.copyWith(
        board: updated,
        statusMessage: 'Board renamed to "${updated.name}"',
      ));
    } catch (e) {
      emit(current.copyWith(statusMessage: 'Rename error: $e'));
    }
  }
}
