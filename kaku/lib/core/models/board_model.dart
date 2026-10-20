import 'dart:convert';

class BoardSummaryModel {
  final String id;
  final String projectId;
  final String name;
  final int revision;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BoardSummaryModel({
    required this.id,
    required this.projectId,
    required this.name,
    this.revision = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BoardSummaryModel.fromJson(Map<String, dynamic> json) {
    return BoardSummaryModel(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Board',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'revision': revision,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class BoardModel {
  final String id;
  final String projectId;
  final String name;
  final Map<String, dynamic> content;
  final Map<String, dynamic> viewport;
  final int revision;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BoardModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.content,
    required this.viewport,
    this.revision = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedContent = {};
    if (json['content'] != null) {
      if (json['content'] is Map) {
        parsedContent = Map<String, dynamic>.from(json['content'] as Map);
      } else if (json['content'] is String) {
        try {
          parsedContent = jsonDecode(json['content'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    Map<String, dynamic> parsedViewport = {'zoom': 1.0, 'panX': 0.0, 'panY': 0.0};
    if (json['viewport'] != null) {
      if (json['viewport'] is Map) {
        parsedViewport = Map<String, dynamic>.from(json['viewport'] as Map);
      } else if (json['viewport'] is String) {
        try {
          parsedViewport = jsonDecode(json['viewport'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    return BoardModel(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Board',
      content: parsedContent,
      viewport: parsedViewport,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'content': content,
      'viewport': viewport,
      'revision': revision,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BoardModel copyWith({
    String? id,
    String? projectId,
    String? name,
    Map<String, dynamic>? content,
    Map<String, dynamic>? viewport,
    int? revision,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoardModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      content: content ?? this.content,
      viewport: viewport ?? this.viewport,
      revision: revision ?? this.revision,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
