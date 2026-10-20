import '../../../../core/models/board_model.dart';
import '../../../../core/models/invitation_model.dart';
import '../../../../core/models/member_model.dart';
import '../../../../core/models/project_model.dart';

sealed class ProjectDetailState {
  const ProjectDetailState();
}

final class ProjectDetailInitial extends ProjectDetailState {
  const ProjectDetailInitial();
}

final class ProjectDetailLoading extends ProjectDetailState {
  const ProjectDetailLoading({this.message = 'Loading workspace...'});
  final String message;
}

final class ProjectDetailLoaded extends ProjectDetailState {
  const ProjectDetailLoaded({
    required this.project,
    required this.boards,
    required this.members,
    required this.invitations,
    this.latestGeneratedToken,
    this.statusMessage,
  });

  final ProjectModel project;
  final List<BoardSummaryModel> boards;
  final List<ProjectMemberModel> members;
  final List<InvitationModel> invitations;
  final String? latestGeneratedToken;
  final String? statusMessage;

  ProjectDetailLoaded copyWith({
    ProjectModel? project,
    List<BoardSummaryModel>? boards,
    List<ProjectMemberModel>? members,
    List<InvitationModel>? invitations,
    String? latestGeneratedToken,
    String? statusMessage,
  }) {
    return ProjectDetailLoaded(
      project: project ?? this.project,
      boards: boards ?? this.boards,
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      latestGeneratedToken: latestGeneratedToken,
      statusMessage: statusMessage,
    );
  }
}

final class ProjectDetailError extends ProjectDetailState {
  const ProjectDetailError(this.errorMessage);
  final String errorMessage;
}
