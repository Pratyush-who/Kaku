import '../models/board_model.dart';
import '../network/api_client.dart';

class BoardRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<BoardSummaryModel>> getProjectBoards(String projectId) async {
    final response = await _api.get('/api/v1/projects/$projectId/boards');
    if (response is List) {
      return response
          .map((item) => BoardSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BoardModel> createBoard({
    required String projectId,
    required String name,
    Map<String, dynamic>? content,
    Map<String, dynamic>? viewport,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
    };
    if (content != null) body['content'] = content;
    if (viewport != null) body['viewport'] = viewport;
    final response = await _api.post('/api/v1/projects/$projectId/boards', body: body);
    if (response is Map<String, dynamic>) {
      return BoardModel.fromJson(response);
    }
    throw ApiException('Failed to create board');
  }

  Future<BoardModel> getBoard(String boardId) async {
    final response = await _api.get('/api/v1/boards/$boardId');
    if (response is Map<String, dynamic>) {
      return BoardModel.fromJson(response);
    }
    throw ApiException('Board not found');
  }

  Future<BoardModel> updateBoardName(String boardId, String name) async {
    final body = {'name': name.trim()};
    final response = await _api.patch('/api/v1/boards/$boardId', body: body);
    if (response is Map<String, dynamic>) {
      return BoardModel.fromJson(response);
    }
    throw ApiException('Failed to rename board');
  }

  Future<int> updateBoardContent({
    required String boardId,
    required Map<String, dynamic> content,
    Map<String, dynamic>? viewport,
    required int expectedRevision,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'expectedRevision': expectedRevision,
    };
    if (viewport != null) body['viewport'] = viewport;
    final response = await _api.put('/api/v1/boards/$boardId/content', body: body);
    if (response is Map<String, dynamic> && response.containsKey('revision')) {
      return (response['revision'] as num).toInt();
    }
    throw ApiException('Failed to update board content');
  }

  Future<BoardModel> duplicateBoard(String boardId, [String? newName]) async {
    final body = <String, dynamic>{};
    if (newName != null && newName.trim().isNotEmpty) {
      body['name'] = newName.trim();
    }
    final response = await _api.post('/api/v1/boards/$boardId/duplicate', body: body);
    if (response is Map<String, dynamic>) {
      return BoardModel.fromJson(response);
    }
    throw ApiException('Failed to duplicate board');
  }

  Future<void> deleteBoard(String boardId) async {
    await _api.delete('/api/v1/boards/$boardId');
  }
}
