import '../../../../core/models/project_model.dart';

sealed class ProjectsState {
  const ProjectsState();
}

final class ProjectsInitial extends ProjectsState {
  const ProjectsInitial();
}

final class ProjectsLoading extends ProjectsState {
  const ProjectsLoading({this.message = 'Loading projects...'});
  final String message;
}

final class ProjectsLoaded extends ProjectsState {
  const ProjectsLoaded({
    required this.projects,
    this.searchQuery = '',
    this.statusMessage,
  });

  final List<ProjectModel> projects;
  final String searchQuery;
  final String? statusMessage;

  List<ProjectModel> get filteredProjects {
    if (searchQuery.trim().isEmpty) return projects;
    final query = searchQuery.trim().toLowerCase();
    return projects.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  ProjectsLoaded copyWith({
    List<ProjectModel>? projects,
    String? searchQuery,
    String? statusMessage,
  }) {
    return ProjectsLoaded(
      projects: projects ?? this.projects,
      searchQuery: searchQuery ?? this.searchQuery,
      statusMessage: statusMessage,
    );
  }
}

final class ProjectsError extends ProjectsState {
  const ProjectsError(this.errorMessage);
  final String errorMessage;
}
