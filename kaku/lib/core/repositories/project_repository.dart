import '../models/invitation_model.dart';
import '../models/member_model.dart';
import '../models/project_model.dart';
import '../network/api_client.dart';

class ProjectRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<ProjectModel>> getProjects() async {
    final response = await _api.get('/api/v1/projects');
    if (response is List) {
      return response
          .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProjectModel> createProject(String name) async {
    final body = {'name': name.trim()};
    final response = await _api.post('/api/v1/projects', body: body);
    if (response is Map<String, dynamic>) {
      return ProjectModel.fromJson(response);
    }
    throw ApiException('Failed to create project');
  }

  Future<ProjectModel> getProjectDetails(String projectId) async {
    final response = await _api.get('/api/v1/projects/$projectId');
    if (response is Map<String, dynamic>) {
      return ProjectModel.fromJson(response);
    }
    throw ApiException('Project not found');
  }

  Future<ProjectModel> updateProjectName(String projectId, String name) async {
    final body = {'name': name.trim()};
    final response = await _api.patch('/api/v1/projects/$projectId', body: body);
    if (response is Map<String, dynamic>) {
      return ProjectModel.fromJson(response);
    }
    throw ApiException('Failed to rename project');
  }

  Future<void> deleteProject(String projectId) async {
    await _api.delete('/api/v1/projects/$projectId');
  }

  Future<List<ProjectMemberModel>> getMembers(String projectId) async {
    final response = await _api.get('/api/v1/projects/$projectId/members');
    if (response is List) {
      return response
          .map((item) => ProjectMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> removeMember(String projectId, String userId) async {
    await _api.delete('/api/v1/projects/$projectId/members/$userId');
  }

  Future<List<InvitationModel>> getInvitations(String projectId) async {
    final response = await _api.get('/api/v1/projects/$projectId/invitations');
    if (response is List) {
      return response
          .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<InvitationCreateResponse> createInvitation({
    required String projectId,
    required String email,
    required String role,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'role': role.toLowerCase(),
    };
    final response = await _api.post('/api/v1/projects/$projectId/invitations', body: body);
    if (response is Map<String, dynamic>) {
      return InvitationCreateResponse.fromJson(response);
    }
    throw ApiException('Failed to generate invitation');
  }

  Future<InvitationModel> inspectInvitation(String token) async {
    final response = await _api.get('/api/v1/invitations/$token');
    if (response is Map<String, dynamic>) {
      return InvitationModel.fromJson(response);
    }
    throw ApiException('Invalid or expired invitation token');
  }

  Future<String> acceptInvitation(String token) async {
    final response = await _api.post('/api/v1/invitations/$token/accept');
    if (response is Map<String, dynamic> && response.containsKey('message')) {
      return response['message'] as String;
    }
    return 'Invitation accepted successfully';
  }
}
