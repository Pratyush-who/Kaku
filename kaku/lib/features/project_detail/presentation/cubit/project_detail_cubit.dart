import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/invitation_model.dart';
import '../../../../core/repositories/board_repository.dart';
import '../../../../core/repositories/project_repository.dart';
import 'project_detail_state.dart';

class ProjectDetailCubit extends Cubit<ProjectDetailState> {
  ProjectDetailCubit({
    required this.projectId,
    ProjectRepository? projectRepository,
    BoardRepository? boardRepository,
  })  : _projectRepo = projectRepository ?? ProjectRepository(),
        _boardRepo = boardRepository ?? BoardRepository(),
        super(const ProjectDetailInitial());

  final String projectId;
  final ProjectRepository _projectRepo;
  final BoardRepository _boardRepo;

  Future<void> loadDetails() async {
    emit(const ProjectDetailLoading());
    try {
      final projectFuture = _projectRepo.getProjectDetails(projectId);
      final boardsFuture = _boardRepo.getProjectBoards(projectId);
      final membersFuture = _projectRepo.getMembers(projectId);
      final invsFuture = _projectRepo.getInvitations(projectId);

      final results = await Future.wait([
        projectFuture,
        boardsFuture,
        membersFuture,
        invsFuture,
      ]);

      emit(ProjectDetailLoaded(
        project: results[0] as dynamic,
        boards: results[1] as dynamic,
        members: results[2] as dynamic,
        invitations: results[3] as dynamic,
      ));
    } catch (e) {
      emit(ProjectDetailError(e.toString()));
    }
  }

  Future<void> createBoard(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await _boardRepo.createBoard(projectId: projectId, name: name.trim());
      await _refreshWorkspace('Board "$name" created successfully');
    } catch (e) {
      _emitStatusError('Failed to create board: $e');
    }
  }

  Future<void> duplicateBoard(String boardId, [String? newName]) async {
    try {
      await _boardRepo.duplicateBoard(boardId, newName);
      await _refreshWorkspace('Board duplicated successfully');
    } catch (e) {
      _emitStatusError('Failed to duplicate board: $e');
    }
  }

  Future<void> renameBoard(String boardId, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      await _boardRepo.updateBoardName(boardId, newName.trim());
      await _refreshWorkspace('Board renamed successfully');
    } catch (e) {
      _emitStatusError('Failed to rename board: $e');
    }
  }

  Future<void> deleteBoard(String boardId) async {
    try {
      await _boardRepo.deleteBoard(boardId);
      await _refreshWorkspace('Board deleted successfully');
    } catch (e) {
      _emitStatusError('Failed to delete board: $e');
    }
  }

  Future<InvitationCreateResponse?> inviteCollaborator({
    required String email,
    required String role,
  }) async {
    try {
      final res = await _projectRepo.createInvitation(
        projectId: projectId,
        email: email,
        role: role,
      );
      final invs = await _projectRepo.getInvitations(projectId);
      if (state is ProjectDetailLoaded) {
        emit((state as ProjectDetailLoaded).copyWith(
          invitations: invs,
          latestGeneratedToken: res.rawToken,
          statusMessage: 'Invitation created! Copy token to share.',
        ));
      }
      return res;
    } catch (e) {
      _emitStatusError('Failed to create invitation: $e');
      return null;
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      await _projectRepo.removeMember(projectId, userId);
      final members = await _projectRepo.getMembers(projectId);
      if (state is ProjectDetailLoaded) {
        emit((state as ProjectDetailLoaded).copyWith(
          members: members,
          statusMessage: 'Member removed from project',
        ));
      }
    } catch (e) {
      _emitStatusError('Failed to remove member: $e');
    }
  }

  Future<void> _refreshWorkspace(String message) async {
    try {
      final project = await _projectRepo.getProjectDetails(projectId);
      final boards = await _boardRepo.getProjectBoards(projectId);
      final members = await _projectRepo.getMembers(projectId);
      final invs = await _projectRepo.getInvitations(projectId);

      emit(ProjectDetailLoaded(
        project: project,
        boards: boards,
        members: members,
        invitations: invs,
        statusMessage: message,
      ));
    } catch (e) {
      _emitStatusError('Refresh failed: $e');
    }
  }

  void _emitStatusError(String error) {
    if (state is ProjectDetailLoaded) {
      emit((state as ProjectDetailLoaded).copyWith(statusMessage: error));
    } else {
      emit(ProjectDetailError(error));
    }
  }
}
