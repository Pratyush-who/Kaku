import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaku/core/common/widgets/user_avatar.dart';
import 'package:kaku/core/models/user_model.dart';

void main() {
  testWidgets('UserAvatar renders fallback initials when avatarUrl is empty', (tester) async {
    const user = UserModel(
      id: '1',
      name: 'Leonardo DaVinci',
      email: 'leo@kaku.app',
      displayName: 'Leonardo DaVinci',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(user: user, radius: 24.0),
        ),
      ),
    );

    expect(find.text('LD'), findsOneWidget);
  });

  testWidgets('UserAvatar shows online status dot when requested', (tester) async {
    const user = UserModel(
      id: '2',
      name: 'Online User',
      email: 'user@kaku.app',
      displayName: 'Online User',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserAvatar(user: user, showOnline: true, isOnline: true),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(UserAvatar),
        matching: find.byType(Stack),
      ),
      findsOneWidget,
    );
    expect(find.text('OU'), findsOneWidget);
  });
}
