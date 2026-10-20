import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/project_repository.dart';
import 'projects_state.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit({ProjectRepository? projectRepository})
      : _projectRepo = projectRepository ?? ProjectRepository(),
        super(const ProjectsInitial());

  final ProjectRepository _projectRepo;

  Future<void> loadProjects() async {
    emit(const ProjectsLoading());
    try {
      final projects = await _projectRepo.getProjects();
      emit(ProjectsLoaded(projects: projects));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  void updateSearchQuery(String query) {
    if (state is ProjectsLoaded) {
      emit((state as ProjectsLoaded).copyWith(searchQuery: query));
    }
  }

  Future<void> createProject(String name) async {
    if (name.trim().isEmpty) return;
    try {
      await _projectRepo.createProject(name);
      final projects = await _projectRepo.getProjects();
      emit(ProjectsLoaded(
        projects: projects,
        statusMessage: 'Project "$name" created successfully!',
      ));
    } catch (e) {
      if (state is ProjectsLoaded) {
        emit((state as ProjectsLoaded).copyWith(statusMessage: 'Error: $e'));
      } else {
        emit(ProjectsError(e.toString()));
      }
    }
  }

  Future<void> updateProjectName(String projectId, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      await _projectRepo.updateProjectName(projectId, newName);
      final projects = await _projectRepo.getProjects();
      emit(ProjectsLoaded(
        projects: projects,
        statusMessage: 'Project renamed successfully',
      ));
    } catch (e) {
      if (state is ProjectsLoaded) {
        emit((state as ProjectsLoaded).copyWith(statusMessage: 'Error: $e'));
      }
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _projectRepo.deleteProject(projectId);
      final projects = await _projectRepo.getProjects();
      emit(ProjectsLoaded(
        projects: projects,
        statusMessage: 'Project deleted successfully',
      ));
    } catch (e) {
      if (state is ProjectsLoaded) {
        emit((state as ProjectsLoaded).copyWith(statusMessage: 'Error: $e'));
      }
    }
  }

  Future<String> acceptInvitationToken(String token) async {
    try {
      final message = await _projectRepo.acceptInvitation(token.trim());
      final projects = await _projectRepo.getProjects();
      emit(ProjectsLoaded(
        projects: projects,
        statusMessage: message,
      ));
      return message;
    } catch (e) {
      rethrow;
    }
  }
}
