import 'package:flutter_test/flutter_test.dart';
import 'package:kaku/core/models/recent_board_model.dart';
import 'package:kaku/core/models/user_model.dart';
import 'package:kaku/core/models/user_preferences_model.dart';
import 'package:kaku/core/models/user_stats_model.dart';

void main() {
  group('UserModel Profile Fields Tests', () {
    test('parses avatarUrl, bio, and preferences properly', () {
      final json = {
        'id': 'u-123',
        'name': 'Test User',
        'email': 'test@kaku.app',
        'displayName': 'Sketch Master',
        'avatarUrl': '/uploads/avatars/avatar_123.png',
        'bio': 'Designing the next generation of wireframes.',
        'preferences': {
          'theme': 'dark',
          'grid': true,
          'snapToGrid': true,
          'emailNotifications': false,
        },
        'createdAt': '2026-10-24T12:00:00Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'u-123');
      expect(user.displayName, 'Sketch Master');
      expect(user.avatarUrl, '/uploads/avatars/avatar_123.png');
      expect(user.bio, 'Designing the next generation of wireframes.');
      expect(user.preferences['theme'], 'dark');
      expect(user.initials, 'SM');
      expect(user.effectiveAvatarUrl, contains('/uploads/avatars/avatar_123.png'));
    });

    test('generates 1 or 2 letter initials correctly', () {
      const user1 = UserModel(
        id: '1',
        name: 'Single',
        email: 's@kaku.app',
        displayName: 'Single',
      );
      expect(user1.initials, 'SI');

      const user2 = UserModel(
        id: '2',
        name: 'John Doe',
        email: 'j@kaku.app',
        displayName: 'John Doe',
      );
      expect(user2.initials, 'JD');
    });

    test('preserves absolute avatar URLs as effective avatar URLs', () {
      const user = UserModel(
        id: '3',
        name: 'Alice',
        email: 'a@kaku.app',
        displayName: 'Alice',
        avatarUrl: 'https://images.unsplash.com/photo-123',
      );
      expect(user.effectiveAvatarUrl, 'https://images.unsplash.com/photo-123');
    });
  });

  group('UserPreferencesModel Tests', () {
    test('default preferences are configured correctly', () {
      const prefs = UserPreferencesModel();
      expect(prefs.theme, 'system');
      expect(prefs.grid, true);
      expect(prefs.snapToGrid, false);
      expect(prefs.emailNotifications, true);
    });

    test('toJson and fromJson work reciprocally', () {
      const prefs = UserPreferencesModel(
        theme: 'light',
        grid: false,
        snapToGrid: true,
        emailNotifications: false,
      );

      final json = prefs.toJson();
      final reconstituted = UserPreferencesModel.fromJson(json);

      expect(reconstituted.theme, 'light');
      expect(reconstituted.grid, false);
      expect(reconstituted.snapToGrid, true);
      expect(reconstituted.emailNotifications, false);
    });
  });

  group('UserStatsModel Tests', () {
    test('parses backend stats response format', () {
      final json = {
        'ownedProjectsCount': 5,
        'sharedProjectsCount': 3,
        'totalProjectsCount': 8,
        'createdBoardsCount': 12,
        'totalBoardsCount': 24,
        'accountCreatedAt': '2026-01-15T08:30:00Z',
      };

      final stats = UserStatsModel.fromJson(json);
      expect(stats.ownedProjectsCount, 5);
      expect(stats.sharedProjectsCount, 3);
      expect(stats.totalProjectsCount, 8);
      expect(stats.createdBoardsCount, 12);
      expect(stats.totalBoardsCount, 24);
      expect(stats.accountCreatedAt?.year, 2026);
    });
  });

  group('RecentBoardModel Tests', () {
    test('parses recent boards activity payload', () {
      final json = {
        'id': 'b-456',
        'projectId': 'p-789',
        'projectName': 'Design System',
        'name': 'Architecture Blueprint',
        'revision': 42,
        'role': 'owner',
        'createdAt': '2026-10-24T10:00:00Z',
        'updatedAt': '2026-10-24T14:30:00Z',
      };

      final board = RecentBoardModel.fromJson(json);
      expect(board.id, 'b-456');
      expect(board.projectName, 'Design System');
      expect(board.name, 'Architecture Blueprint');
      expect(board.revision, 42);
      expect(board.role, 'owner');
    });
  });
}
